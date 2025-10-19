#!/usr/bin/env bash
set -euo pipefail

# Fix signature issues for apps that won't launch
# WARNING: This will reset accessibility permissions!

echo "⚠️  WARNING: Re-signing will reset accessibility permissions!"
echo "You'll need to re-grant permissions in System Settings → Privacy & Security"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo "🔓 Removing quarantine attributes..."
xattr -cr /Applications/BabyKeyboardLock.app

echo "✍️  Re-signing with ad-hoc signature..."
codesign --force --deep --sign - /Applications/BabyKeyboardLock.app

echo "✅ Signature fixed!"
echo ""
echo "📝 Next steps:"
echo "1. Open System Settings → Privacy & Security → Accessibility"
echo "2. Re-add BabyKeyboardLock to the allowed apps"
