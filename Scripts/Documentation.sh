#!/bin/sh

#  Documentation.sh
#  MapirLiveTracker
#
#  Created by Alireza Asadi on 2/8/1398 AP.
#  Copyright © 1398 AP Map. All rights reserved.

set -euo pipefail

function step { >&2 echo "\033[1m\033[36m$@\033[0m"; }

SDK_VERSION=$(make sdk_version)

DOCUMENTATION_ASSETS_DIR="Documentation"
THEME_DIR="${DOCUMENTATION_ASSETS_DIR}/theme"
GUIDES_DIR="${DOCUMENTATION_ASSETS_DIR}/guides"
OUTPUT_DIR="docs"

README="README.md"
JAZZY_CONF=".jazzy.yaml"

step "🛠 Generating documentation."

rm -rf ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}

jazzy \
    --config ${JAZZY_CONF} \
    --readme ${README} \
    --sdk ios \
    --clean \
    --author Map.ir \
    --author_url https://map.ir \
    --module-version ${SDK_VERSION} \
    --build-tool-arguments -scheme,MapirLiveTracker-iOS \
    --module MapirLiveTracker \
    --github-url https://github.com/map-ir/mapir-ios-tracker \
    --root-url https://map-ir.github.io/mapir-ios-tracker \
    --output ${OUTPUT_DIR} \
    --theme ${THEME_DIR}

step "🎷 Created."
