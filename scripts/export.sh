#!/usr/bin/env bash
set -euo pipefail

# Export archive to application bundle

echo "📤 Exporting app..."
mkdir -p build

# Create ExportOptions.plist
cat > build/ExportOptions.plist <<- 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>mac-application</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
</dict>
</plist>
PLIST

# Export archive
xcodebuild -exportArchive \
	-archivePath ./build/BabyKeyboardLock.xcarchive \
	-exportPath ./build/export \
	-exportOptionsPlist ./build/ExportOptions.plist
