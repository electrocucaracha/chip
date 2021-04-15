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

if [ ! -d "$chip_src" ]; then
    sudo git clone --depth 1 --recurse-submodules https://github.com/project-chip/connectedhomeip "$chip_src"
    sudo chown -R "$USER": "$chip_src"
fi

pushd "$chip_src"
git submodule update --init

# shellcheck disable=SC1091
source scripts/activate.sh
gn gen out/host --args="is_debug=${DEBUG:-false}"
ninja -C out/host
popd
