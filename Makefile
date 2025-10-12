.PHONY: deploy update clean archive export install

# Main target - build and deploy the app
deploy: archive export install
	@echo "✅ BabyKeyboardLock deployed successfully to /Applications/"

# Alias for deploy - update the installed app
update: deploy

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build/

# Build archive
archive: clean
	@echo "📦 Building archive..."
	@xcodebuild clean archive \
		-project BabyKeyboardLock.xcodeproj \
		-scheme BabyKeyboardLock \
		-configuration Release \
		-archivePath ./build/BabyKeyboardLock.xcarchive

# Export archive
export:
	@echo "📤 Exporting app..."
	@mkdir -p build
	@cat > build/ExportOptions.plist << 'PLIST'
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
	@xcodebuild -exportArchive \
		-archivePath ./build/BabyKeyboardLock.xcarchive \
		-exportPath ./build/export \
		-exportOptionsPlist ./build/ExportOptions.plist

# Install to Applications folder
install:
	@echo "📲 Installing to /Applications/..."
	@cp -R ./build/export/BabyKeyboardLock.app /Applications/
	@echo "✨ Installation complete!"
