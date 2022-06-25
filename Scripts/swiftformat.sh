#!/bin/sh

if [[ $BISMUSH_SKIP_TEST == 1 ]]; then
    echo "Skip swiftformat because BISMUSH_SKIP_TEST is set"
else
    cd BuildTools
    swift run swiftformat --filelist "${SCRIPT_INPUT_FILE_LIST_0}" --report Reports/${TARGETNAME}.format.json
fi
