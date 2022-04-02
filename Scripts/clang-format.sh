#!/bin/sh
echo nhnoeth
if [[ $BISMUSH_SKIP_TEST == 1 ]]; then
    echo "Skip swiftformat because BISMUSH_SKIP_TEST is set"
    exit 0
fi

if which clang-format > /dev/null; then
  cd "$SRCROOT"
  find . -name "*.metal" -exec clang-format -i \{\} \;
fi
