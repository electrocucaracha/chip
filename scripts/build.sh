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

if [ ! -d "$chip_src" ]; then
    sudo git clone --depth 1 --recurse-submodules https://github.com/project-chip/connectedhomeip "$chip_src"
    sudo chown -R "$USER": "$chip_src"
else
    pushd "$chip_src"
    git submodule update --init
    git pull origin master
    popd
fi

pushd "$chip_src"
sudo rm -rf out/
popd

bootstrap
for build_type in gcc_debug gcc_release clang mbedtls clang_experimental; do
    init "$build_type"
    trap cleanup EXIT

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

    # Run Tests
    run ./scripts/tests/gn_tests.sh
done
