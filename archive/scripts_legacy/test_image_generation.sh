#!/bin/bash
# Test image generation with both methods

set -e

echo "=== Testing Image Generation ==="
echo ""

# Pick 3 random words from the word sets (prefer missing ones)
WORDS=$(uv run python -c "
import random
import sys
from pathlib import Path

# Add parent dir to path to import from generate_with_nano_banana
sys.path.insert(0, str(Path('scripts').resolve()))
from generate_with_nano_banana import get_all_unique_words

# Get all words
all_words = list(get_all_unique_words())

# Check which ones are missing crayon images
output_dir = Path('dev/Resources/FlashcardImages/crayon')
if output_dir.exists():
    existing = {f.stem.replace('crayon_', '') for f in output_dir.glob('crayon_*.png')}
    missing_words = [w for w in all_words if w.replace(' ', '_').lower() not in existing]
else:
    missing_words = all_words

# Pick from missing if available, otherwise from all
word_pool = missing_words if missing_words else all_words
selected = random.sample(word_pool, min(3, len(word_pool)))
print(' '.join(selected))
")

echo "Selected words: $WORDS"
echo ""

# 1. Generate a few images with nano-banana (Gemini)
echo "1) Generating images with nano-banana..."
uv run python scripts/generate_with_nano_banana.py \
    --words $WORDS \
    --style crayon \
    --model nano-banana

echo ""
echo "2) Downloading Quick Draw dataset for same words..."
uv run python -c "
import sys
from pathlib import Path
sys.path.insert(0, str(Path.home() / 'calmmage' / 'calmlib'))
from datasets.quickdraw_downloader import QuickDrawDownloader

words = '$WORDS'.split()
downloader = QuickDrawDownloader(Path('quickdraw_data'))
for word in words:
    try:
        downloader.download_category(word)
    except Exception as e:
        print(f'⚠ Could not download {word}: {e}')
print('✓ Downloaded Quick Draw data to quickdraw_data/')
"

echo ""
echo "=== Done! ==="
