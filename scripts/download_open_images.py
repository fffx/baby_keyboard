#!/usr/bin/env python3
"""
Download Open Images dataset photos for baby flashcards.

Uses the openimages Python package to download real photos of objects.
Install: pip install openimages
"""

from pathlib import Path
import subprocess
import sys

# Word sets from RandomWordList.swift
WORD_SETS = {
    "basic": ["mama", "papa", "arm", "leg", "nose", "eye", "family", "dog", "cat"],
    "starter": ["mama", "papa", "baby", "milk", "water", "yes", "no", "bye", "hi", "love"],
    "animals_easy": ["cat", "dog", "bird", "fish", "cow", "duck", "pig", "rabbit", "mouse", "bear"],
    "food_easy": ["apple", "banana", "bread", "cookie", "juice", "egg", "cheese", "cake", "soup", "tea"],
    "body_parts": ["head", "eye", "nose", "mouth", "ear", "hand", "finger", "leg", "foot", "belly", "hair", "tooth"],
    "colors": ["red", "blue", "green", "yellow", "orange", "purple", "pink", "brown", "black", "white", "gray"],
    "actions_easy": ["eat", "drink", "sleep", "walk", "run", "jump", "play", "sit", "stand", "look"],
    "animals_medium": ["horse", "sheep", "chicken", "lion", "tiger", "elephant", "giraffe", "monkey", "zebra", "frog", "butterfly", "snake", "turtle", "penguin", "owl"],
    "food_medium": ["orange", "grape", "strawberry", "watermelon", "carrot", "potato", "tomato", "cucumber", "ice cream", "pizza", "pasta", "rice", "meat", "chicken", "sandwich"],
    "toys": ["ball", "doll", "teddy bear", "car", "train", "bike", "block", "puzzle", "book", "swing", "slide", "drum"],
    "nature": ["sun", "moon", "star", "cloud", "rain", "snow", "tree", "flower", "grass", "water", "sky", "wind"],
    "actions_medium": ["dance", "sing", "read", "draw", "write", "clap", "wave", "hug", "kiss", "laugh", "cry", "smile"],
    "vehicles": ["car", "bus", "truck", "train", "plane", "helicopter", "boat", "ship", "rocket", "bicycle"],
    "family": ["grandma", "grandpa", "brother", "sister", "aunt", "uncle", "cousin", "friend", "family", "home"]
}


def get_all_unique_words() -> set[str]:
    """Extract all unique words from all word sets."""
    all_words = set()
    for word_list in WORD_SETS.values():
        all_words.update(word_list)
    return all_words


def capitalize_word(word: str) -> str:
    """Capitalize word for Open Images labels (e.g., 'apple' -> 'Apple')."""
    # Handle multi-word phrases
    return ' '.join(w.capitalize() for w in word.split())


def check_openimages_installed():
    """Check if openimages package is installed."""
    try:
        import openimages
        return True
    except ImportError:
        return False


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Download Open Images dataset for baby flashcards")
    parser.add_argument("--limit", type=int, default=10, help="Number of images per word (default: 10)")
    parser.add_argument("--words", nargs="+", help="Specific words to download")
    parser.add_argument("--output", type=Path, default=Path("./openimages_photos"),
                       help="Output directory (default: ./openimages_photos)")
    parser.add_argument("--test", action="store_true", help="Test mode: only download 3 words")
    parser.add_argument("--dry-run", action="store_true", help="Show plan without downloading")

    args = parser.parse_args()

    print(f"\n{'='*60}")
    print(f"OPEN IMAGES DATASET DOWNLOADER")
    print(f"{'='*60}")
    print(f"Dataset: Open Images v7 (9M images, 6000+ categories)")
    print(f"License: Creative Commons Attribution 4.0")
    print(f"Output: {args.output}")

    # Check if openimages is installed
    if not check_openimages_installed():
        print(f"\n❌ ERROR: openimages package not installed")
        print(f"\nPlease install it first:")
        print(f"  uv pip install openimages")
        print(f"\nOr:")
        print(f"  pip install openimages")
        sys.exit(1)

    # Get words
    if args.words:
        words = args.words
    else:
        words = sorted(get_all_unique_words())

    # Test mode: only 3 words
    if args.test:
        words = words[:3]
        print(f"\n🧪 TEST MODE: Only downloading {len(words)} words")

    # Convert to Open Images labels (capitalized)
    labels = [capitalize_word(w) for w in words]

    print(f"\nWords to download: {len(words)}")
    print(f"Images per word: {args.limit}")
    print(f"Total images: ~{len(words) * args.limit}")
    print(f"\nFirst 20 words:")
    for i, (word, label) in enumerate(zip(words[:20], labels[:20]), 1):
        print(f"  {i:2d}. {word:20s} -> {label}")
    if len(words) > 20:
        print(f"  ... and {len(words) - 20} more")

    print(f"{'='*60}\n")

    if args.dry_run:
        print("Dry run complete (no images downloaded)")
        return

    # Confirm
    response = input("Proceed with download? (yes/no): ")
    if response.lower() != "yes":
        print("Cancelled.")
        return

    # Create output directories
    csv_dir = args.output / "csv"
    images_dir = args.output / "images"
    csv_dir.mkdir(parents=True, exist_ok=True)
    images_dir.mkdir(parents=True, exist_ok=True)

    print("\nDownloading using openimages package...")
    print(f"Command: oi_download_images")

    # Build command
    cmd = [
        "oi_download_images",
        "--csv_dir", str(csv_dir),
        "--base_dir", str(images_dir),
        "--labels"
    ] + labels + [
        "--limit", str(args.limit)
    ]

    print(f"\nRunning: {' '.join(cmd)}\n")

    # Run the download
    try:
        result = subprocess.run(cmd, check=True)

        print(f"\n{'='*60}")
        print(f"DOWNLOAD COMPLETE")
        print(f"{'='*60}")

        # Count downloaded images
        total_images = sum(1 for _ in images_dir.rglob("*.jpg"))

        print(f"✓ Downloaded images: {total_images}")
        print(f"Location: {images_dir}")
        print(f"CSV metadata: {csv_dir}")

    except subprocess.CalledProcessError as e:
        print(f"\n❌ ERROR: Download failed")
        print(f"Error: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print(f"\n❌ ERROR: oi_download_images command not found")
        print(f"\nMake sure openimages is installed:")
        print(f"  uv pip install openimages")
        sys.exit(1)

    print(f"{'='*60}\n")

    # Instructions
    print("Next steps:")
    print("1. Review downloaded images in images/")
    print("2. Select best images for each word")
    print("3. Copy selected images to BabyKeyboardLock/Resources/FlashcardImages/")
    print("4. Update FlashcardStyle.swift to use real photos instead of drawings")


if __name__ == "__main__":
    main()
