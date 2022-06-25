#!/bin/sh

if [[ $BISMUSH_SKIP_TEST == 1 ]]; then
    echo "Skip swiftlint because BISMUSH_SKIP_TEST is set"
else
    cd BuildTools
    swift run -c release swiftlint --use-script-input-files --fix
fi
