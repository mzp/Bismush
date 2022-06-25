#!/bin/sh

if [[ $BISMUSH_SKIP_TEST == 1 ]]; then
    echo "Skip swiftlint because BISMUSH_SKIP_TEST is set"
else
    cd BuildTools
    cat "${SCRIPT_INPUT_FILE_LIST_0}" | xargs swift run swiftlint lint | tee Reports/${TARGETNAME}.lint.txt
fi
