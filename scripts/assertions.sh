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
    local error_msg=${2:-"$1 doesn't exist"}

    info "File exists Assertion - value: $1"
    if [ ! -f "$input" ]; then
        error "$error_msg"
    fi
}
