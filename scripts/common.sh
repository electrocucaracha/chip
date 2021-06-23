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

chip_src="/opt/connectedhomeip"
DOCKER_CMD="sudo $(command -v docker)"

# info() - This function prints an information message in the standard output
function info {
    _print_msg "INFO" "$1"
}

# error() - This function prints an error message in the standard output
function error {
    _print_msg "ERROR" "$1"
    exit 1
}

function _print_msg {
    echo "$(date +%H:%M:%S) - $1: $2"
}

# bootstrap() - Creates the docker builder image used during the compilation
function bootstrap {
    pushd "${chip_src}/integrations/docker/images/chip-build"
    $DOCKER_CMD build --build-arg VERSION="$(cat version)" -t chip-builder .
    popd
}

# init() - Initializes a builder container
function init {
    cleanup
    $DOCKER_CMD run -ti --rm --name builder -d \
    --env BUILD_TYPE="$1" \
    -w "$chip_src" \
    -v "${chip_src}:${chip_src}" \
    --sysctl "net.ipv6.conf.all.disable_ipv6=0 net.ipv4.conf.all.forwarding=1 net.ipv6.conf.all.forwarding=1" \
    chip-builder
}

# run() - Executes a command on a running builder container
function run {
    $DOCKER_CMD exec builder sh -c "$@"
}

# cleanup() - Destroy an existing builder container
function cleanup {
    if [[ -n "$($DOCKER_CMD ps -aqf "name=builder")" ]]; then
        $DOCKER_CMD kill builder
        sleep 5
    fi
}
