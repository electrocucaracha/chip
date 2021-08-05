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
# shellcheck source=./scripts/_int_tests.sh
source _int_tests.sh

function _init {
    cleanup_containers

    $DOCKER_CMD run -ti --rm --name builder -d \
    -w "$chip_src" \
    -v "${chip_src}:${chip_src}" \
    --sysctl "net.ipv6.conf.all.disable_ipv6=0 net.ipv4.conf.all.forwarding=1 net.ipv6.conf.all.forwarding=1" \
    connectedhomeip/chip-build
}

trap cleanup EXIT
for eventloop in eventloop_same eventloop_separate; do
    _init

    # Bootstrap
    run ./scripts/build/gn_bootstrap.sh

    # Build all clusters app
    run "scripts/examples/gn_build_example.sh examples/all-clusters-app/linux out/debug/standalone/ chip_config_network_layer_ble=false is_tsan=true"
    add_msg "All cluster apps were built successfully"

    # Build TV app
    run "scripts/examples/gn_build_example.sh examples/tv-app/linux out/debug/standalone/ chip_config_network_layer_ble=false is_tsan=true"
    add_msg "TV app was built sucessfully"

    # Build chip-tool
    USE_SEPARATE_EVENTLOOP=$([[ $eventloop == "eventloop_separate" ]] && echo "true" || echo "false")
    run "scripts/examples/gn_build_example.sh examples/chip-tool out/debug/standalone/ is_tsan=true config_use_separate_eventloop=${USE_SEPARATE_EVENTLOOP} config_pair_with_random_id=false"
    add_msg "CHIP tool built sucessfully(USE_SEPARATE_EVENTLOOP=$USE_SEPARATE_EVENTLOOP)"

    # Run Tests
    run "scripts/tests/test_suites.sh"
    add_msg "Test suites ran sucessfully"

    run "scripts/tests/test_suites.sh -a tv"
    add_msg "TV Test suites ran sucessfully"

    print_stats
done
