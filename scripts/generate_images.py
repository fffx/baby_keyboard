#!/usr/bin/env python3
"""Simple bulk image generation helper for Baby Keyboard assets."""

import argparse
import asyncio
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Sequence

from calmlib.llm.bulk_image_generation import (
    BulkGenerationConfig,
    BulkImageGenerator,
    bulk_generate_images,
)
from word_utils import sample_english_words, unique_english_words

from dotenv import load_dotenv
load_dotenv()

# Friendly style presets that map to short prompt snippets
STYLE_PRESETS = {
    "crayon": "Children's crayon drawing, bold outlines, bright colors, waxy texture",
    "doodle": "Simple hand-drawn doodle, clean black lines, minimal shading, high contrast",
    "pencil": "Soft pencil sketch, light shading, gentle graphite texture, minimal color",
    "simple": "Simple cool image of the requested object",
    "watercolor": "Playful watercolor wash, soft gradients, organic textures, storybook vibe",
    "mosaic": "Pale glass mosaic, thick black outlines, soft light rays, drifting dust, moody atmosphere",
    "elvish": "Elven craftsmanship, dark emerald and gold accents, metallic shine, intricate filigree, magical glow",
}


@dataclass(frozen=True)
class GenerationItem:
    prompt: str
    filename: str
    word: str


def resolve_output_dir(output: Path) -> Path:
    """Ensure the output directory exists and return it."""
    output.mkdir(parents=True, exist_ok=True)
    return output


def load_words(
    words: Sequence[str] | None,
    words_file: Path | None,
    sample_size: int,
    use_all_defaults: bool,
    seed: int | None,
) -> List[str]:
    """Collate words from CLI arguments, a file, or default Swift sources."""
    collected: set[str] = set()

    if words:
        collected.update(w.strip() for w in words if w.strip())

    if words_file:
        with words_file.open("r", encoding="utf-8") as fh:
            for line in fh:
                candidate = line.strip()
                if candidate and not candidate.startswith("#"):
                    collected.add(candidate)

    if collected:
        return sorted(collected)

    # Default: use all words if nothing specified
    if use_all_defaults or sample_size <= 0:
        return unique_english_words()

    return sample_english_words(sample_size, seed=seed)


def build_prompt(word: str, style_key: str, custom_style: str | None) -> str:
    """Return a short, consistent image prompt."""
    description = custom_style or STYLE_PRESETS.get(style_key)
    if not description:
        available = ", ".join(sorted(STYLE_PRESETS))
        raise SystemExit(f"Unknown style '{style_key}'. Try one of: {available}")

    display_word = word.replace("_", " ")
    return (
        f"{description}. Clear, centered illustration of '{display_word}'. "
        "Child-friendly, 1:1 aspect ratio, high contrast, no text."
    )


def build_items(words: Iterable[str], style_key: str, custom_style: str | None, output_dir: Path) -> list[GenerationItem]:
    """Create generation payload for calmlib, filtering out existing images."""
    items: list[GenerationItem] = []
    for word in words:
        sanitized = word.replace(" ", "_").lower()
        filename = f"{style_key}_{sanitized}.png"

        # Skip if image already exists
        if (output_dir / filename).exists():
            continue

        items.append(
            GenerationItem(
                prompt=build_prompt(word, style_key, custom_style),
                filename=filename,
                word=word,
            )
        )
    return items


def preview(items: Sequence[GenerationItem], generator: BulkImageGenerator) -> None:
    """Print a quick summary and estimated cost."""
    cost = generator.estimate_cost(len(items))
    print(f"\nPreparing to generate {len(items)} image(s)")
    print(f"Estimated cost: ${cost:.2f}")
    print("\nSample prompts:")
    for item in items[: min(5, len(items))]:
        print(f"  - {item.word}: {item.prompt}")


async def generate(
    items: Sequence[GenerationItem],
    output_dir: Path,
    model: str | None,
    size: str,
    max_concurrent: int,
) -> None:
    """Trigger the bulk generation and log a short summary."""
    results = await bulk_generate_images(
        items=[{"prompt": it.prompt, "filename": it.filename} for it in items],
        output_dir=output_dir,
        model=model,
        size=size,
        max_concurrent=max_concurrent,
    )

    successes = sum(1 for r in results if r.success)
    failures = len(results) - successes
    total_cost = sum(getattr(r, "cost", 0.0) for r in results)

    print("\nGeneration complete")
    print(f"  ✓ Successes : {successes}")
    if failures:
        print(f"  ✗ Failures : {failures}")
    print(f"  💲 Cost     : ${total_cost:.2f}")
    print(f"  📁 Output   : {output_dir}")


async def main() -> None:
    parser = argparse.ArgumentParser(description="Generate images via calmlib bulk generator")
    parser.add_argument(
        "--words",
        nargs="+",
        help="One or more words to illustrate (space separated)",
    )
    parser.add_argument(
        "--words-file",
        type=Path,
        help="Optional file containing one word per line",
    )
    parser.add_argument(
        "--style",
        help=f"Style preset name (default: all styles). Options: {', '.join(sorted(STYLE_PRESETS))}, or 'all'",
    )
    parser.add_argument(
        "--style-prompt",
        help="Override the style description with a custom prompt snippet",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Directory to store generated images (default: auto-determined by style)",
    )
    parser.add_argument(
        "--model",
        help="Optional calmlib model identifier (defaults to calmlib's auto selection)",
    )
    parser.add_argument(
        "--size",
        default="1024x1024",
        help="Image size accepted by the underlying provider",
    )
    parser.add_argument(
        "--max-concurrent",
        type=int,
        default=5,
        help="Concurrent generation tasks (default: 5)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview prompts and cost without generating images",
    )
    parser.add_argument(
        "--sample-size",
        type=int,
        default=0,
        help="Randomly sample this many default words when none are provided (default: 0 = all words)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        help="Optional random seed for sampling default words",
    )
    parser.add_argument(
        "--all-defaults",
        action="store_true",
        help="Use every default word from RandomWordList.swift (ignores --sample-size)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="Limit total number of images to generate across all styles",
    )

    args = parser.parse_args()

    words = load_words(args.words, args.words_file, args.sample_size, args.all_defaults, args.seed)

    # Determine which styles to process
    if args.style and args.style.lower() != "all":
        styles_to_process = [args.style]
    else:
        styles_to_process = sorted(STYLE_PRESETS.keys())

    base_dir = Path(__file__).resolve().parent.parent / "BabyKeyboardLock" / "Resources" / "FlashcardImages"
    config = BulkGenerationConfig(model=args.model)
    generator = BulkImageGenerator(config)

    # Collect all items across all styles
    all_items = []
    total_skipped = 0

    for style in styles_to_process:
        if args.output:
            output_dir = resolve_output_dir(args.output)
        else:
            output_dir = resolve_output_dir(base_dir / style)

        items = build_items(words, style, args.style_prompt, output_dir)
        skipped = len(words) - len(items)
        total_skipped += skipped

        # Store output_dir with items for later use
        for item in items:
            all_items.append((item, output_dir, style))

    if total_skipped > 0:
        print(f"\nSkipped {total_skipped} existing image(s) across all styles")

    if not all_items:
        print("\nAll images already exist. Nothing to generate.")
        return

    # Apply limit if specified
    if args.limit and args.limit > 0:
        original_count = len(all_items)
        all_items = all_items[:args.limit]
        if original_count > args.limit:
            print(f"\nLimited to {args.limit} images (from {original_count} total)")

    # Preview
    print(f"\nPreparing to generate {len(all_items)} image(s) across {len(styles_to_process)} style(s)")
    cost = generator.estimate_cost(len(all_items))
    print(f"Estimated cost: ${cost:.2f}")
    print(f"\nStyles: {', '.join(styles_to_process)}")
    print("\nSample prompts:")
    for item, _, _ in all_items[: min(5, len(all_items))]:
        print(f"  - {item.word}: {item.prompt}")

    if args.dry_run:
        print("\nDry run complete. Run again without --dry-run to generate images.")
        return

    confirmation = input("\nGenerate images now? (yes/no): ").strip().lower()
    if confirmation not in {"y", "yes"}:
        print("Cancelled.")
        return

    # Generate all items by style
    total_successes = 0
    total_failures = 0
    total_cost = 0.0

    for style in styles_to_process:
        style_items = [(item, out_dir) for item, out_dir, s in all_items if s == style]
        if not style_items:
            continue

        items_only = [item for item, _ in style_items]
        output_dir = style_items[0][1]

        print(f"\n{'='*60}")
        print(f"Generating {len(items_only)} images for style: {style}")
        print(f"{'='*60}")

        results = await bulk_generate_images(
            items=[{"prompt": it.prompt, "filename": it.filename} for it in items_only],
            output_dir=output_dir,
            model=args.model,
            size=args.size,
            max_concurrent=args.max_concurrent,
        )

        successes = sum(1 for r in results if r.success)
        failures = len(results) - successes
        cost = sum(getattr(r, "cost", 0.0) for r in results)

        total_successes += successes
        total_failures += failures
        total_cost += cost

        print(f"\nStyle '{style}' complete: {successes} succeeded, {failures} failed, ${cost:.2f}")

    print(f"\n{'='*60}")
    print("All styles complete")
    print(f"  ✓ Total successes : {total_successes}")
    if total_failures:
        print(f"  ✗ Total failures  : {total_failures}")
    print(f"  💲 Total cost     : ${total_cost:.2f}")


if __name__ == "__main__":
    asyncio.run(main())
