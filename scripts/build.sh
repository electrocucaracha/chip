#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o errexit
if [[ "${DEBUG:-false}" == "true" ]]; then
    set -o xtrace
fi

# shellcheck source=./scripts/common.sh
source common.sh
# shellcheck source=./scripts/assertions.sh
source assertions.sh
# shellcheck source=./scripts/tests.sh
source tests.sh

function _cleanup {
    info "Cleaning previous execution"
    cleanup_containers
    cleanup_images
    pushd "$chip_src"
    sudo rm -rf out/
    popd
}

trap _cleanup EXIT
for build_type in gcc_debug gcc_release clang mbedtls clang_experimental; do
    init "$build_type"

    case "$build_type" in
        "gcc_debug") GN_ARGS='chip_config_memory_debug_checks=true chip_config_memory_debug_dmalloc=true';;
        "gcc_release") GN_ARGS='is_debug=false';;
        "clang") GN_ARGS='is_clang=true';;
        "mbedtls") GN_ARGS='chip_crypto="mbedtls"';;
    esac

    # Use gn to generate Ninja files
    run ./scripts/build/gn_gen.sh --args="$GN_ARGS"

    # Build source code
    run ./scripts/build/gn_build.sh

    # Verify binaries creation
    run_file_asserts "$chip_src/out/$build_type"

    # Run Unit Tests
    run ./scripts/tests/gn_tests.sh

    if [[ "${FUNCTIONAL_TEST_ENABLED:-false}" == "true" ]]; then
        # Run Integration Tests
        bootstrap_int_test "$build_type"

        # Echo - Functional Test
        run_int_test "$build_type" echo-responder echo-requester

        run_common_asserts 3
        info "Running Echo assertions"
        assert_contains responder "Listening for Echo requests..."
        assert_count_equal requester "Send echo request message to Node:" 3
        assert_count_equal responder "sending response." 3

        # IM - Functional Test
        run_int_test "$build_type" im-responder im-initiator

        run_common_asserts 10
        info "Running IM assertions"
        assert_contains responder "Listening for IM requests..."
        assert_count_equal requester "Sending secure msg on generic transport" 20
    fi
done
