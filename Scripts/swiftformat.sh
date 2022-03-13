#!/bin/sh

cd BuildTools
SDKROOT=(xcrun --sdk macosx --show-sdk-path)
swift run -c release swiftformat "$SRCROOT"
