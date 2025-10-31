#!/usr/bin/env python3
"""
Generate flashcard images using calmlib bulk generation utilities.

This script uses the new bulk_image_generation utilities from calmlib.
"""

import asyncio
# import sys
from pathlib import Path

# Add calmlib to path
# calmlib_path = Path.home() / "calmmage" / "calmlib"
# sys.path.insert(0, str(calmlib_path))

from calmlib.llm.bulk_image_generation import bulk_generate_images, BulkGenerationConfig, BulkImageGenerator

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

# Image styles
STYLES = {
    "crayon": "Children's crayon drawing style, colorful, simple shapes, waxy texture",
    "doodle": "Simple hand-drawn doodle style, black and white line art, playful",
    "pencil": "Pencil sketch style, gentle shading, soft lines, artistic",
    "simple": "Minimalist simple flat design, clean shapes, educational illustration"
}


def get_all_unique_words() -> set[str]:
    """Extract all unique words from all word sets."""
    all_words = set()
    for word_list in WORD_SETS.values():
        all_words.update(word_list)
    return all_words


def generate_prompt(word: str, style: str) -> str:
    """Generate prompt for a word in a specific style."""
    style_description = STYLES[style]

    word_display = word.replace("_", " ")

    prompt = f"""Create a {style_description} illustration of: {word_display}

Requirements:
- Child-friendly and educational
- Clear and recognizable representation
- Suitable for toddlers/young children (1-3 years old)
- No text or words in the image
- Square aspect ratio (1:1)
- High contrast and visibility
- Safe, non-scary, positive imagery

Style: {style_description}
"""
    return prompt


async def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate flashcard images using calmlib")
    parser.add_argument("--style", choices=list(STYLES.keys()), help="Generate specific style")
    parser.add_argument("--limit", type=int, help="Limit number of images")
    parser.add_argument("--words", nargs="+", help="Generate specific words")
    parser.add_argument("--model", help="Model to use (default: auto-select)")
    parser.add_argument("--dry-run", action="store_true", help="Show plan without generating")

    args = parser.parse_args()

    # Get words
    if args.words:
        words = set(args.words)
    else:
        words = get_all_unique_words()

    # Get styles
    styles = [args.style] if args.style else list(STYLES.keys())

    # Build generation items
    items = []
    output_dir = Path(__file__).parent.parent / "Resources" / "FlashcardImages"

    for style in styles:
        for word in sorted(words):
            filename_word = word.replace(" ", "_").lower()
            filename = f"{style}_{filename_word}.png"

            # Check if already exists
            output_path = output_dir / style / filename
            if output_path.exists():
                continue

            items.append({
                "prompt": generate_prompt(word, style),
                "filename": f"{style}/{filename}",
                "word": word,
                "style": style
            })

    # Apply limit
    if args.limit:
        items = items[:args.limit]

    # Show plan
    print(f"\n{'='*60}")
    print(f"FLASHCARD GENERATION (using calmlib utilities)")
    print(f"{'='*60}")
    print(f"Total unique words: {len(words)}")
    print(f"Styles: {', '.join(styles)}")
    print(f"Images to generate: {len(items)}")

    if len(items) > 0:
        # Use calmlib to estimate cost
        config = BulkGenerationConfig(model=args.model)
        generator = BulkImageGenerator(config)
        cost = generator.estimate_cost(len(items), args.model)

        print(f"Estimated cost: ${cost:.2f}")
        print(f"Model: {args.model or 'auto-select'}")
        print(f"\nFirst few items:")
        for item in items[:10]:
            print(f"  - {item['style']:10s} : {item['word']}")
        if len(items) > 10:
            print(f"  ... and {len(items) - 10} more")

    print(f"{'='*60}\n")

    if len(items) == 0:
        print("✓ All images already exist!")
        return

    if args.dry_run:
        print("Dry run complete (no images generated)")
        return

    # Confirm
    response = input("Proceed with generation? (yes/no): ")
    if response.lower() != "yes":
        print("Cancelled.")
        return

    # Generate using calmlib utilities!
    print("\nGenerating images using calmlib.llm.bulk_image_generation...")

    results = await bulk_generate_images(
        items=items,
        output_dir=output_dir,
        model=args.model,
        size="1024x1024",
        max_concurrent=5,
    )

    # Summary
    successful = sum(1 for r in results if r.success)
    failed = len(results) - successful
    total_cost = sum(r.cost for r in results)

    print(f"\n{'='*60}")
    print(f"GENERATION COMPLETE")
    print(f"{'='*60}")
    print(f"✓ Successfully generated: {successful}")
    if failed > 0:
        print(f"✗ Failed: {failed}")
    print(f"Total cost: ${total_cost:.2f}")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    asyncio.run(main())
