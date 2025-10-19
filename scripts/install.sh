#!/usr/bin/env bash
set -euo pipefail

# Install application to /Applications/ folder

echo "📲 Installing to /Applications/..."
cp -R ./build/export/BabyKeyboardLock.app /Applications/

echo "✨ Installation complete!"
echo ""
echo "💡 If the app won't open, run: make fix-signature"
