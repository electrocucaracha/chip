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

# bootstrap_int_test() - Packages the binaries into docker containers
function bootstrap_int_test {
    local build_type="$1"

    dockerfile_path="$(realpath Dockerfile)"
    pushd "${chip_src}/out/${build_type}"
    $DOCKER_CMD build -t "chip-${build_type}" -f "$dockerfile_path" .
    popd
}

# run_int_test() - Runs an Integration test
function run_int_test {
    local build_type="$1"
    local responder="$2"
    local requester="$3"
    attempt_counter=0
    max_attempts=5

    cleanup_containers
    $DOCKER_CMD run -d --net host --rm --name responder "chip-${build_type}" "./chip-$responder"
    until $DOCKER_CMD logs responder | grep -q "New pairing for device"; do
        if [ ${attempt_counter} -eq ${max_attempts} ];then
            error "Max attempts reached"
        fi
        attempt_counter=$((attempt_counter+1))
        sleep $((attempt_counter*2))
    done
    $DOCKER_CMD run --net host --name requester "chip-${build_type}" "./chip-$requester" 127.0.0.1 > /dev/null
}
