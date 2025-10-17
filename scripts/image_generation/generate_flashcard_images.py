#!/usr/bin/env python3
"""
Bulk generate flashcard images for BabyKeyboardLock using AI image generation.

This script:
1. Extracts all unique words from the word sets
2. Generates images in multiple styles (crayon, doodle, pencil, simple)
3. Saves images with the correct naming convention
4. Tracks progress and estimates costs
5. Supports resume functionality if interrupted

Usage:
    python generate_flashcard_images.py --dry-run  # Preview what will be generated
    python generate_flashcard_images.py --style crayon  # Generate only one style
    python generate_flashcard_images.py  # Generate all missing images
"""

import argparse
import json
import sys
from pathlib import Path
from typing import List, Dict, Set
import time

# Add calmlib to path
calmlib_path = Path.home() / "calmmage" / "calmlib"
if calmlib_path.exists():
    sys.path.insert(0, str(calmlib_path))
    try:
        from llm.litellm_wrapper import get_llm_provider
        HAS_LLM = True
    except ImportError as e:
        print(f"Warning: Could not import LLM utils: {e}")
        print("Will run in planning mode only")
        HAS_LLM = False
        get_llm_provider = None
else:
    print(f"Warning: calmlib not found at {calmlib_path}")
    print("Will run in planning mode only")
    HAS_LLM = False
    get_llm_provider = None

# Word sets extracted from RandomWordList.swift
WORD_SETS = {
    "basic": [
        "mama", "papa", "arm", "leg", "nose", "eye", "family", "dog", "cat"
    ],
    "starter": [
        "mama", "papa", "baby", "milk", "water", "yes", "no", "bye", "hi", "love"
    ],
    "animals_easy": [
        "cat", "dog", "bird", "fish", "cow", "duck", "pig", "rabbit", "mouse", "bear"
    ],
    "food_easy": [
        "apple", "banana", "bread", "cookie", "juice", "egg", "cheese", "cake", "soup", "tea"
    ],
    "body_parts": [
        "head", "eye", "nose", "mouth", "ear", "hand", "finger", "leg", "foot",
        "belly", "hair", "tooth"
    ],
    "colors": [
        "red", "blue", "green", "yellow", "orange", "purple", "pink", "brown",
        "black", "white", "gray"
    ],
    "actions_easy": [
        "eat", "drink", "sleep", "walk", "run", "jump", "play", "sit", "stand", "look"
    ],
    "animals_medium": [
        "horse", "sheep", "chicken", "lion", "tiger", "elephant", "giraffe", "monkey",
        "zebra", "frog", "butterfly", "snake", "turtle", "penguin", "owl"
    ],
    "food_medium": [
        "orange", "grape", "strawberry", "watermelon", "carrot", "potato", "tomato",
        "cucumber", "ice cream", "pizza", "pasta", "rice", "meat", "chicken", "sandwich"
    ],
    "toys": [
        "ball", "doll", "teddy bear", "car", "train", "bike", "block", "puzzle",
        "book", "swing", "slide", "drum"
    ],
    "nature": [
        "sun", "moon", "star", "cloud", "rain", "snow", "tree", "flower", "grass",
        "water", "sky", "wind"
    ],
    "actions_medium": [
        "dance", "sing", "read", "draw", "write", "clap", "wave", "hug", "kiss",
        "laugh", "cry", "smile"
    ],
    "vehicles": [
        "car", "bus", "truck", "train", "plane", "helicopter", "boat", "ship",
        "rocket", "bicycle"
    ],
    "family": [
        "grandma", "grandpa", "brother", "sister", "aunt", "uncle", "cousin",
        "friend", "family", "home"
    ]
}

# Image styles from FlashcardStyle.swift
STYLES = {
    "crayon": "Children's crayon drawing style, colorful, simple shapes, waxy texture",
    "doodle": "Simple hand-drawn doodle style, black and white line art, playful",
    "pencil": "Pencil sketch style, gentle shading, soft lines, artistic",
    "simple": "Minimalist simple flat design, clean shapes, educational illustration"
}

OUTPUT_DIR = Path(__file__).parent.parent / "Resources" / "FlashcardImages"


def get_all_unique_words() -> Set[str]:
    """Extract all unique words from all word sets."""
    all_words = set()
    for word_list in WORD_SETS.values():
        all_words.update(word_list)
    return all_words


def get_existing_images() -> Dict[str, Set[str]]:
    """Check which images already exist for each style."""
    existing = {style: set() for style in STYLES.keys()}

    for style in STYLES.keys():
        style_dir = OUTPUT_DIR / style
        if style_dir.exists():
            for img_file in style_dir.glob("*.png"):
                # Extract word from filename: style_word.png or style_style_word.png
                filename = img_file.stem
                # Remove style prefix(es)
                word = filename.replace(f"{style}_", "").replace(f"{style}_", "")
                existing[style].add(word)

    return existing


def generate_image_prompt(word: str, style: str) -> str:
    """Generate a detailed prompt for image generation."""
    style_description = STYLES[style]

    # Special handling for multi-word phrases
    if " " in word:
        word_display = word.replace("_", " ")
    else:
        word_display = word

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


def estimate_cost(num_images: int, model: str = "dall-e-3") -> float:
    """Estimate the cost of generating images."""
    # DALL-E 3 pricing (as of 2024): ~$0.04 per 1024x1024 image
    # Adjust based on actual pricing
    cost_per_image = 0.04
    return num_images * cost_per_image


def generate_image(word: str, style: str, llm_provider, dry_run: bool = False) -> Path:
    """Generate a single image using AI."""
    prompt = generate_image_prompt(word, style)

    # Sanitize filename
    filename_word = word.replace(" ", "_").lower()
    filename = f"{style}_{filename_word}.png"
    output_path = OUTPUT_DIR / style / filename

    if dry_run:
        print(f"[DRY RUN] Would generate: {output_path}")
        print(f"  Prompt: {prompt[:100]}...")
        return output_path

    print(f"Generating: {output_path}")

    # Create output directory if needed
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Generate image using LLM provider
    # Note: This requires image generation capability
    # For now, this is a placeholder - you'll need to integrate with DALL-E or similar
    try:
        # TODO: Integrate with actual image generation API
        # response = llm_provider.generate_image(prompt=prompt, size="1024x1024")
        # image_url = response.data[0].url
        # Download and save image
        print(f"  TODO: Implement actual image generation for: {word}")

    except Exception as e:
        print(f"  ERROR: Failed to generate {word} in {style} style: {e}")
        return None

    return output_path


def main():
    parser = argparse.ArgumentParser(description="Bulk generate flashcard images")
    parser.add_argument("--style", choices=list(STYLES.keys()),
                       help="Generate only one specific style")
    parser.add_argument("--dry-run", action="store_true",
                       help="Preview what will be generated without actually generating")
    parser.add_argument("--limit", type=int,
                       help="Limit number of images to generate (for testing)")
    parser.add_argument("--words", nargs="+",
                       help="Generate only specific words")

    args = parser.parse_args()

    # Get all words
    if args.words:
        all_words = set(args.words)
    else:
        all_words = get_all_unique_words()

    # Get existing images
    existing_images = get_existing_images()

    # Determine which styles to generate
    styles_to_generate = [args.style] if args.style else list(STYLES.keys())

    # Calculate what needs to be generated
    generation_plan = []
    for style in styles_to_generate:
        for word in sorted(all_words):
            if word not in existing_images[style]:
                generation_plan.append((word, style))

    # Apply limit if specified
    if args.limit:
        generation_plan = generation_plan[:args.limit]

    # Display summary
    print(f"\n{'='*60}")
    print(f"FLASHCARD IMAGE GENERATION PLAN")
    print(f"{'='*60}")
    print(f"Total unique words: {len(all_words)}")
    print(f"Styles: {', '.join(styles_to_generate)}")
    print(f"Images to generate: {len(generation_plan)}")

    if len(generation_plan) > 0:
        estimated_cost = estimate_cost(len(generation_plan))
        print(f"Estimated cost: ${estimated_cost:.2f}")
        print(f"\nFirst few items:")
        for word, style in generation_plan[:10]:
            print(f"  - {style:10s} : {word}")
        if len(generation_plan) > 10:
            print(f"  ... and {len(generation_plan) - 10} more")

    print(f"{'='*60}\n")

    if len(generation_plan) == 0:
        print("No images to generate. All images already exist!")
        return

    # Confirm before proceeding (unless dry-run)
    if not args.dry_run:
        response = input("Proceed with generation? (yes/no): ")
        if response.lower() != "yes":
            print("Cancelled.")
            return

    # Initialize LLM provider
    llm_provider = get_llm_provider() if HAS_LLM else None

    # Generate images
    generated = 0
    failed = 0

    for i, (word, style) in enumerate(generation_plan, 1):
        print(f"\n[{i}/{len(generation_plan)}] ", end="")
        result = generate_image(word, style, llm_provider, dry_run=args.dry_run)

        if result:
            generated += 1
        else:
            failed += 1

        # Rate limiting - avoid hitting API too fast
        if not args.dry_run and i < len(generation_plan):
            time.sleep(1)  # 1 second between requests

    # Summary
    print(f"\n{'='*60}")
    print(f"GENERATION COMPLETE")
    print(f"{'='*60}")
    print(f"Successfully generated: {generated}")
    print(f"Failed: {failed}")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
