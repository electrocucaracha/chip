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

# run_common_asserts() - This functions verifies that binaries were created properly
function run_file_asserts {
    output_path="$1"

    info "Verifying binaries creation"

    for bin in echo-requester echo-responder im-initiator im-responder shell tool; do
        assert_file_exists "$output_path/chip-$bin"
    done
}

# run_common_asserts() - This function runs multiple common assertions
function run_common_asserts {
    msg_counter=$1

    info "Running Common assertions"

    assert_non_empty requester
    assert_contains requester "Establish secure session succeeded"
    assert_contains responder "Secure transport received message destined to"
    assert_contains responder "Setting fabricID"

    assert_count_equal responder "Received message of type" "$((msg_counter*2))"
    assert_count_equal requester "Secure msg send status No Error" "$((msg_counter*2))"
    assert_count_equal responder "Secure msg send status No Error" "$msg_counter"

    assert_contains requester "Inet Layer shutdown"
    assert_contains requester "BLE layer shutdown"
    assert_contains requester "System Layer shutdown"
}

# cleanup() - Print
function cleanup {
    _print_summary

    info "Cleaning previous execution"
    cleanup_containers
    if [[ "${CHIP_DEV_MODE:-false}" == "false" ]]; then
        cleanup_images
    fi
    pushd "$chip_src"
    sudo rm -rf out/
    popd
}

trap cleanup EXIT
for build_type in gcc_debug gcc_release clang mbedtls; do
    init "$build_type"

    case "$build_type" in
        "gcc_debug") GN_ARGS='chip_config_memory_debug_checks=true chip_config_memory_debug_dmalloc=true';;
        "gcc_release") GN_ARGS='is_debug=false';;
        "clang") GN_ARGS='is_clang=true';;
        "mbedtls") GN_ARGS='chip_crypto="mbedtls"';;
    esac

    # Bootstrap
    run ./scripts/build/gn_bootstrap.sh

    # Use gn to generate Ninja files
    run "./scripts/build/gn_gen.sh --args='$GN_ARGS'"
    msg+="- Ninja files generated successfully for $build_type\n"

    # Build source code
    run ./scripts/build/gn_build.sh
    msg+="- $build_type build was successfully\n"
    copy "$chip_src/out/$build_type"

    # Verify binaries creation
    run_file_asserts "/tmp/$build_type"
    msg+="- $build_type assertions were passed successfully\n"

    # Run Unit Tests
    run ./scripts/tests/gn_tests.sh
    msg+="- $build_type passed their unit tests\n"

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
        msg+="- INFO: $build_type passed echo functional test\n"

        # IM - Functional Test
        run_int_test "$build_type" im-responder im-initiator

        run_common_asserts 10
        info "Running IM assertions"
        assert_contains responder "Listening for IM requests..."
        assert_count_equal requester "Sending secure msg on generic transport" 20
        msg+="- INFO: $build_type passed IM functional test\n"
    fi
done
