#!/bin/sh

#  BuildForDistribution.sh
#  MapirLiveTracker
#
#  Created by Alireza Asadi on 13/8/1398 AP.
#  Copyright © 1398 AP Map. All rights reserved.

set -euo pipefail

BUILD_DIR="Build"
ARCHIVES_DIR="${BUILD_DIR}/Archives"
DERIVED_DATA_DIR="${BUILD_DIR}/DerviedData"
OUTPUT_DIR="${BUILD_DIR}/Output"

MODULE_NAME="MapirLiveTracker"
SCHEME="${MODULE_NAME}-iOS"
OUTPUT_NAME="${MODULE_NAME}.xcframework"

function step { >&2 echo "\033[1m\033[36m$@\033[0m"; }

if [ -d ${BUILD_DIR} ]
then
    rm -rf ${ARCHIVES_DIR}
    rm -rf ${DERIVED_DATA_DIR}
    rm -rf ${OUTPUT_DIR}
else
    mkdir ${BUILD_DIR}
fi

# Build for iOS
IPHONE_ARCHIVE_PATH="${ARCHIVES_DIR}/ios.xcarchive"

step "Building for iOS..."
xcodebuild archive \
    -scheme ${SCHEME} \
    -destination="iOS" \
    -sdk iphoneos \
    -archivePath ${IPHONE_ARCHIVE_PATH} \
    -derivedDataPath "${DERIVED_DATA_DIR}/iphoneos" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
    -quiet

step "Done."

# Build for iOS Simulator
IPHONE_SIM_ARCHIVE_PATH="${ARCHIVES_DIR}/iossim.xcarchive"

step "Building for iOS Simulator..."
xcodebuild archive \
    -scheme ${SCHEME} \
    -destination="iOS Simulator" \
    -sdk iphonesimulator \
    -archivePath ${IPHONE_SIM_ARCHIVE_PATH} \
    -derivedDataPath "${DERIVED_DATA_DIR}/iphonesimulator" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
    -quiet

step "Done."

# Creatin XCFramework

step "Creating XCFramework..."

IPHONE_FRAMEWORK_PATH="${IPHONE_ARCHIVE_PATH}/Products/Library/Frameworks/${MODULE_NAME}.framework"
IPHONE_SIM_FRAMEWORK_PATH="${IPHONE_SIM_ARCHIVE_PATH}/Products/Library/Frameworks/${MODULE_NAME}.framework"

xcodebuild -create-xcframework \
    -framework ${IPHONE_FRAMEWORK_PATH} \
    -framework ${IPHONE_SIM_FRAMEWORK_PATH} \
    -output "${OUTPUT_DIR}/${OUTPUT_NAME}" \

step "Done."
open "${OUTPUT_DIR}"
