#!/bin/bash
# Test image generation with both methods

set -e

echo "=== Testing Image Generation ==="
echo ""

# 1. Generate a few images with nano-banana (Gemini)
echo "1) Generating 3 test images with nano-banana..."
uv run python scripts/generate_with_nano_banana.py \
    --words cat dog apple \
    --style crayon \
    --model nano-banana

echo ""
echo "2) Downloading Quick Draw dataset for a few categories..."
uv run python -c "
import sys
from pathlib import Path
sys.path.insert(0, str(Path.home() / 'calmmage' / 'calmlib'))
from datasets.quickdraw_downloader import QuickDrawDownloader

downloader = QuickDrawDownloader(Path('quickdraw_data'))
downloader.download_category('cat')
downloader.download_category('dog')
downloader.download_category('apple')
print('✓ Downloaded Quick Draw data to quickdraw_data/')
"

echo ""
echo "=== Done! ==="
