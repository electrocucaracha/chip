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
mgmt_nic="$(ip route get 1.1.1.1 | awk 'NR==1 { print $5 }')"
ratio=$((1024*1024)) # MB
msg="Summary \n"
start=$(date +%s)
if [ -f "/sys/class/net/$mgmt_nic/statistics/rx_bytes" ]; then
    rx_bytes_before=$(cat "/sys/class/net/$mgmt_nic/statistics/rx_bytes")
fi

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

function bootstrap {
    _init_src
    _print_stats
    _init_img
    _print_stats
}

function _git_timed {
    local count=0
    local timeout=0

    if [[ -n "${GIT_TIMEOUT}" ]]; then
        timeout=${GIT_TIMEOUT}
    fi

    until timeout -s SIGINT "${timeout}" sudo git "$@"; do
        # 124 is timeout(1)'s special return code when it reached the
        # timeout; otherwise assume fatal failure
        if [[ $? -ne 124 ]]; then
            info "git call failed: [git $*]"
        fi

        if [ $count -eq 3 ]; then
            error "Maximum of 3 git retries reached"
        fi
        count=$((count+1))
        sleep $((count*5))
    done
}

function _init_src {
    if [ ! -d "$chip_src" ]; then
        info "Cloning Connnected Home IP source code"
        _git_timed clone --depth 1 --recurse-submodules https://github.com/project-chip/connectedhomeip "$chip_src"
        sudo chown -R "$USER": "$chip_src"
    fi

    info "Updating Connnected Home IP source code"
    pushd "$chip_src"
    _git_timed submodule update --init
    _git_timed pull origin master
    popd
}

function _init_img {
    if [[ "${CHIP_BUILD_IMAGE:-false}" == "true" ]]; then
        info "Building Connnected Home IP builder image"
        pushd "${chip_src}/integrations/docker/images/chip-build"
        $DOCKER_CMD build --build-arg VERSION="$(cat version)" -t connectedhomeip/chip-build .
        popd
    else
        info "Pulling Connnected Home IP builder image"
        $DOCKER_CMD pull connectedhomeip/chip-build
    fi
}

# init() - Initializes a builder container
function init {
    cleanup_containers

    $DOCKER_CMD run -ti --rm --name builder -d \
    --env BUILD_TYPE="$1" \
    -w "$chip_src" \
    -v "${chip_src}:${chip_src}" \
    --sysctl "net.ipv6.conf.all.disable_ipv6=0 net.ipv4.conf.all.forwarding=1 net.ipv6.conf.all.forwarding=1" \
    connectedhomeip/chip-build
}

# run() - Executes a command on a running builder container
function run {
    info "Running inside of the container - $*"
    $DOCKER_CMD exec builder sh -c "$@"
}

# cleanup_images() - Remove previous docker images
function cleanup_images {
    for img in $($DOCKER_CMD images -f reference="chip-*" -q); do
        $DOCKER_CMD rmi -f "$img"
    done
}

# cleanup_containers() - Destroy builder and functional test containers
function cleanup_containers {
    max_attempts=5

    for container in $($DOCKER_CMD ps -aq); do
        pid=$($DOCKER_CMD inspect --format '{{.State.Pid}}' "$container")
        $DOCKER_CMD kill "$container" ||:
        if [ "${pid:-0}" != "0" ]; then
            until [ -z "$(ps -p "$pid" -o comm=)" ]; do
                if [ "${attempt_counter}" -eq "${max_attempts}" ];then
                    error "Max attempts reached"
                fi
                attempt_counter=$((attempt_counter+1))
                sleep $((attempt_counter*2))
            done
        fi
        $DOCKER_CMD rm -f "$container" ||:
    done
}

function _print_stats {
    if [ -f "/sys/class/net/$mgmt_nic/statistics/rx_bytes" ]; then
        rx_bytes_after=$(cat "/sys/class/net/$mgmt_nic/statistics/rx_bytes")
    fi
    echo "=== Statistics ==="
    echo "Duration time: $(($(date +%s)-start)) secs"
    if [ -n "${rx_bytes_before:-}" ] && [ -n "${rx_bytes_after:-}" ]; then
        echo "Network usage: $(((rx_bytes_after-rx_bytes_before)/ratio)) MB"
    fi
}

function _print_summary {
    echo -e "$msg\n"
    _print_stats
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
