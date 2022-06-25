#!/bin/sh

if [[ $BISMUSH_SKIP_TEST == 1 ]]; then
    echo "Skip swiftformat because BISMUSH_SKIP_TEST is set"
else
    cd BuildTools
    for i in {0..$SCRIPT_INPUT_FILE_LIST_COUNT}
    do
      swift run -c release swiftformat "$SRCROOT" --filelist "${SCRIPT_INPUT_FILE_LIST_$i}"
    done
fi
