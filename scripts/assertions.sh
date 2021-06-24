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

# assert_file_exists() - This assertion checks if the given file exists
function assert_file_exists {
    local input=$1

    info "File exists Assertion - value: $input"
    if [ ! -f "$input" ]; then
        error "${2:-"$1 doesn't exist"}"
    fi
}

# assert_non_empty() - This assertion checks if the container's logs are not empty
function assert_non_empty {
    input="$($DOCKER_CMD logs "$1")"

    info "NonEmpty Assertion - container: $1"
    if [ -z "$input" ]; then
        error "${2:-"There is no input provided"}"
    fi
}

# assert_contains() - This assertion checks if the container's log contains a specific string
function assert_contains {
    input="$($DOCKER_CMD logs "$1")"
    local expected=$2

    info "Contains Assertion - container: $1 expected: $expected"
    if [[ "$input" != *"$expected"* ]]; then
        error "${3:-"The input doesn't contain the expected string"}"
    fi
}

# assert_count_equal() - This assertion checks if the container's log contains a number of string matches
function assert_count_equal {
    local expected=$3

    info "Count equal Assertion - regex: $2 count expected: $expected"
    if [[ "$($DOCKER_CMD logs "$1" | grep -c "$2")" != "$expected" ]]; then
        error "${4:-"The $1 logs don't have $expected string matches"}"
    fi
}

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
