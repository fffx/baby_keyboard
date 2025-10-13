#!/usr/bin/env bash
set -euo pipefail

# Build archive using xcodebuild

echo "📦 Building archive..."
xcodebuild clean archive \
	-project BabyKeyboardLock.xcodeproj \
	-scheme BabyKeyboardLock \
	-configuration Release \
	-archivePath ./build/BabyKeyboardLock.xcarchive
