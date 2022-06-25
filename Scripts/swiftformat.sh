#!/bin/sh

if [[ $BISMUSH_SKIP_TEST == 1 ]]; then
    echo "Skip swiftformat because BISMUSH_SKIP_TEST is set"
else
    cd BuildTools
    SDKROOT=(xcrun --sdk macosx --show-sdk-path)
    swift run swiftformat --filelist "${SCRIPT_INPUT_FILE_LIST_0}" --report Reports/${TARGETNAME}.format.json
fi
