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

bootstrap
"./${CHIP_CI_SCRIPT:-build}.sh"
