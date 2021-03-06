#!/bin/sh

if [[ $BISMUSH_SKIP_TEST == 1 ]]; then
    echo "Skip swiftlint because BISMUSH_SKIP_TEST is set"
else
    cd BuildTools
    SDKROOT=(xcrun --sdk macosx --show-sdk-path)
    cat "${SCRIPT_INPUT_FILE_LIST_0}" | xargs swift run -Xlinker "-no_compact_unwind" swiftlint lint | tee Reports/${TARGETNAME}.lint.txt
fi
