#!/usr/bin/env python3
"""
Generate flashcard images using DALL-E 3.

This is a production-ready implementation using OpenAI's DALL-E API.
"""

import os
import sys
from pathlib import Path
import requests
import time
from typing import Optional

try:
    from openai import OpenAI
except ImportError:
    print("Error: openai package not installed")
    print("Install with: pip install openai")
    sys.exit(1)

# Import the base generation script
sys.path.insert(0, str(Path(__file__).parent))
from generate_flashcard_images import (
    get_all_unique_words,
    get_existing_images,
    STYLES,
    OUTPUT_DIR,
    generate_image_prompt
)


def generate_with_dalle(word: str, style: str, client: OpenAI, dry_run: bool = False) -> Optional[Path]:
    """Generate an image using DALL-E 3."""

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

    try:
        # Create output directory
        output_path.parent.mkdir(parents=True, exist_ok=True)

        # Generate image with DALL-E 3
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1024",
            quality="standard",
            n=1,
        )

        # Get the image URL
        image_url = response.data[0].url

        # Download the image
        img_response = requests.get(image_url, timeout=30)
        img_response.raise_for_status()

        # Save the image
        with open(output_path, 'wb') as f:
            f.write(img_response.content)

        print(f"  ✓ Saved to: {output_path}")
        return output_path

    except Exception as e:
        print(f"  ✗ ERROR: {e}")
        return None


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate flashcard images with DALL-E 3")
    parser.add_argument("--style", choices=list(STYLES.keys()),
                       help="Generate only one specific style")
    parser.add_argument("--dry-run", action="store_true",
                       help="Preview without generating")
    parser.add_argument("--limit", type=int,
                       help="Limit number of images")
    parser.add_argument("--words", nargs="+",
                       help="Generate only specific words")
    parser.add_argument("--delay", type=float, default=2.0,
                       help="Delay between API calls (default: 2.0 seconds)")

    args = parser.parse_args()

    # Check API key
    api_key = os.getenv("OPENAI_API_KEY") or os.getenv("CALMMAGE_OPENAI_API_KEY")
    if not api_key and not args.dry_run:
        print("Error: OpenAI API key not found!")
        print("Set one of these environment variables:")
        print("  - OPENAI_API_KEY")
        print("  - CALMMAGE_OPENAI_API_KEY")
        sys.exit(1)

    # Initialize OpenAI client
    client = OpenAI(api_key=api_key) if not args.dry_run else None

    # Get words to generate
    if args.words:
        all_words = set(args.words)
    else:
        all_words = get_all_unique_words()

    # Get existing images
    existing_images = get_existing_images()

    # Determine styles to generate
    styles_to_generate = [args.style] if args.style else list(STYLES.keys())

    # Calculate generation plan
    generation_plan = []
    for style in styles_to_generate:
        for word in sorted(all_words):
            if word not in existing_images[style]:
                generation_plan.append((word, style))

    # Apply limit
    if args.limit:
        generation_plan = generation_plan[:args.limit]

    # Display summary
    print(f"\n{'='*60}")
    print(f"DALL-E 3 IMAGE GENERATION")
    print(f"{'='*60}")
    print(f"Total words: {len(all_words)}")
    print(f"Styles: {', '.join(styles_to_generate)}")
    print(f"Images to generate: {len(generation_plan)}")

    if len(generation_plan) > 0:
        # DALL-E 3 pricing: $0.040 per image (1024x1024, standard quality)
        cost = len(generation_plan) * 0.040
        print(f"Estimated cost: ${cost:.2f}")
        print(f"\nFirst few items:")
        for word, style in generation_plan[:10]:
            print(f"  - {style:10s} : {word}")
        if len(generation_plan) > 10:
            print(f"  ... and {len(generation_plan) - 10} more")

    print(f"{'='*60}\n")

    if len(generation_plan) == 0:
        print("✓ All images already exist!")
        return

    # Confirm
    if not args.dry_run:
        response = input("Proceed with generation? (yes/no): ")
        if response.lower() != "yes":
            print("Cancelled.")
            return

    # Generate images
    generated = 0
    failed = 0

    for i, (word, style) in enumerate(generation_plan, 1):
        print(f"\n[{i}/{len(generation_plan)}] ", end="")
        result = generate_with_dalle(word, style, client, dry_run=args.dry_run)

        if result:
            generated += 1
        else:
            failed += 1

        # Rate limiting
        if not args.dry_run and i < len(generation_plan):
            time.sleep(args.delay)

    # Summary
    print(f"\n{'='*60}")
    print(f"GENERATION COMPLETE")
    print(f"{'='*60}")
    print(f"✓ Successfully generated: {generated}")
    if failed > 0:
        print(f"✗ Failed: {failed}")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
