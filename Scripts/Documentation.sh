#!/bin/sh

#  Documentation.sh
#  MapirLiveTracker
#
#  Created by Alireza Asadi on 2/8/1398 AP.
#  Copyright © 1398 AP Map. All rights reserved.

set -euo pipefail

function step { >&2 echo "\033[1m\033[36m$@\033[0m"; }


cd ..

step "🧩 Enter module version:"
read MODULE_VERSION
THEME="Documentation/theme"
OUTPUT="Documentation/theme"
README="Readme.md"
JAZZY_CONF=".jazzy.yaml"

rm -rf ${OUTPUT}
mkdir ${OUTPUT}

step "🎷 Generating Jazzy Docs."
jazzy \
    --config ${JAZZY_CONF} \
    --readme ${README} \
    --sdk ios \
    --clean \
    --author Map.ir \
    --author_url https://map.ir \
    --module-version ${MODULE_VERSION} \
    --build-tool-arguments -scheme,MapirLiveTracker-iOS \
    --module MapirLiveTracker \
    --root-url https://support.map.ir/developer/ios/live-tracking/${MODULE_VERSION}/ \
    --output ${OUTPUT} \
    --theme ${THEME}
