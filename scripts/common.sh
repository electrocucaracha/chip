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

function bootstrap {
    pushd "${chip_src}/integrations/docker/images/chip-build"
    $DOCKER_CMD build --build-arg VERSION="$(cat version)" -t chip-builder .
    popd
}

function init {
    $DOCKER_CMD run -ti --rm --name builder -d \
    --env BUILD_TYPE=gcc_release \
    -w "$chip_src" \
    -v "${chip_src}:${chip_src}" \
    --sysctl "net.ipv6.conf.all.disable_ipv6=0 net.ipv4.conf.all.forwarding=1 net.ipv6.conf.all.forwarding=1" \
    chip-builder
}

function run {
    $DOCKER_CMD exec builder sh -c "$@"
}

function cleanup {
    $DOCKER_CMD kill builder
}
