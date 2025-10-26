#!/usr/bin/env python3
"""
Download Google Quick Draw dataset images for baby flashcards.

Uses calmlib.datasets.quickdraw_downloader utilities.
"""

from pathlib import Path

from calmlib.datasets.quickdraw_downloader import QuickDrawDownloader, BABY_FRIENDLY_CATEGORIES


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Download Quick Draw dataset for baby flashcards")
    parser.add_argument("--limit", type=int, help="Limit number of categories to download")
    parser.add_argument("--categories", nargs="+", help="Specific categories to download")
    parser.add_argument("--extract-samples", type=int, help="Extract N sample images per category")
    parser.add_argument("--output", type=Path, default=Path("./quickdraw_images"),
                       help="Output directory")

    args = parser.parse_args()

    print(f"\n{'='*60}")
    print(f"QUICK DRAW DATASET DOWNLOADER")
    print(f"{'='*60}")
    print(f"Dataset: Google Quick Draw (50M drawings, 345 categories)")
    print(f"License: Creative Commons Attribution 4.0")
    print(f"Output: {args.output}")

    # Determine categories
    if args.categories:
        categories = args.categories
        print(f"Categories: {len(categories)} custom")
    else:
        categories = BABY_FRIENDLY_CATEGORIES[:args.limit] if args.limit else BABY_FRIENDLY_CATEGORIES
        print(f"Categories: {len(categories)} baby-friendly")

    print(f"\nCategories to download:")
    for i, cat in enumerate(categories[:20], 1):
        print(f"  {i}. {cat}")
    if len(categories) > 20:
        print(f"  ... and {len(categories) - 20} more")

    print(f"{'='*60}\n")

    # Confirm
    response = input("Proceed with download? (yes/no): ")
    if response.lower() != "yes":
        print("Cancelled.")
        return

    # Download using calmlib utilities
    print("\nDownloading using calmlib.datasets.quickdraw_downloader...")

    downloader = QuickDrawDownloader(args.output / "data")

    downloaded_files = []
    for i, category in enumerate(categories, 1):
        print(f"\n[{i}/{len(categories)}] Downloading {category}...")
        result = downloader.download_category(category)
        if result:
            downloaded_files.append(result)

    print(f"\n{'='*60}")
    print(f"DOWNLOAD COMPLETE")
    print(f"{'='*60}")
    print(f"✓ Downloaded: {len(downloaded_files)}/{len(categories)} categories")
    print(f"Location: {args.output / 'data'}")

    # Extract samples if requested
    if args.extract_samples and downloaded_files:
        print(f"\nExtracting {args.extract_samples} sample images per category...")

        samples_dir = args.output / "samples"
        total_samples = 0

        for file in downloaded_files:
            category_name = file.stem
            category_samples_dir = samples_dir / category_name

            samples = downloader.extract_sample_images(
                file,
                category_samples_dir,
                num_samples=args.extract_samples,
                image_size=(512, 512)
            )
            total_samples += len(samples)

        print(f"✓ Extracted {total_samples} sample images")
        print(f"Location: {samples_dir}")

    print(f"{'='*60}\n")

    # Instructions
    print("Next steps:")
    print("1. Review downloaded images in samples/")
    print("2. Select which categories to use for flashcards")
    print("3. Copy selected images to BabyKeyboardLock/Resources/FlashcardImages/")
    print("4. Update FlashcardStyle.swift if needed")


if __name__ == "__main__":
    main()
