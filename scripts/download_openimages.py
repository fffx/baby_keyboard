#!/usr/bin/env python3
"""Download Open Images samples grouped by word using FiftyOne."""

from __future__ import annotations

import argparse
import random
from pathlib import Path
import shutil
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

import fiftyone as fo
import fiftyone.core.labels as fol
import fiftyone.zoo as foz
from fiftyone.utils import openimages as foi
from word_utils import unique_english_words

# Manual overrides for Open Images class names that differ from our words
LABEL_OVERRIDES: Dict[str, str] = {
    "mama": "Woman",
    "papa": "Man",
    "baby": "Baby",
    "grandma": "Grandmother",
    "grandpa": "Grandfather",
    "brother": "Boy",
    "sister": "Girl",
    "aunt": "Woman",
    "uncle": "Man",
    "cousin": "Child",
    "family": "Family",
    "dog": "Dog",
    "cat": "Cat",
}

OPENIMAGES_CLASSES = set(foi.get_classes())

LABEL_VARIANTS: Dict[str, Tuple[str, ...]] = {
    "arm": ("Human arm",),
    "leg": ("Human leg",),
    "nose": ("Human nose",),
    "eye": ("Human eye",),
    "mouth": ("Human mouth",),
    "ear": ("Human ear",),
    "hand": ("Human hand",),
    "finger": ("Human hand",),
    "foot": ("Human foot",),
    "belly": ("Human body",),
    "hair": ("Human hair",),
    "cow": ("Cattle",),
    "milk": ("Milk",),
    "juice": ("Juice",),
    "egg": ("Egg (Food)",),
    "bread": ("Bread",),
    "cookie": ("Cookie",),
    "cheese": ("Cheese",),
    "cake": ("Cake",),
    "tea": ("Tea",),
    "banana": ("Banana",),
    "apple": ("Apple",),
    "watermelon": ("Watermelon",),
    "orange": ("Orange",),
    "grape": ("Grape",),
    "strawberry": ("Strawberry",),
    "carrot": ("Carrot",),
    "potato": ("Potato",),
    "tomato": ("Tomato",),
    "cucumber": ("Cucumber",),
    "ice cream": ("Ice cream",),
    "pizza": ("Pizza",),
    "pasta": ("Pasta",),
    "sandwich": ("Sandwich",),
    "chicken": ("Chicken",),
    "ball": ("Ball",),
    "doll": ("Doll",),
    "book": ("Book",),
    "train": ("Train",),
    "car": ("Car",),
    "truck": ("Truck",),
    "bus": ("Bus",),
    "plane": ("Airplane",),
    "helicopter": ("Helicopter",),
    "boat": ("Boat",),
    "ship": ("Ship",),
    "rocket": ("Rocket",),
    "bicycle": ("Bicycle",),
    "bike": ("Bicycle",),
    "block": ("Toy",),
    "lion": ("Lion",),
    "tiger": ("Tiger",),
    "elephant": ("Elephant",),
    "giraffe": ("Giraffe",),
    "monkey": ("Monkey",),
    "zebra": ("Zebra",),
    "frog": ("Frog",),
    "butterfly": ("Butterfly",),
    "snake": ("Snake",),
    "turtle": ("Turtle",),
    "penguin": ("Penguin",),
    "owl": ("Owl",),
    "pig": ("Pig",),
    "duck": ("Duck",),
    "bird": ("Bird",),
    "fish": ("Fish",),
    "cat": ("Cat",),
    "dog": ("Dog",),
    "mouse": ("Mouse",),
    "bear": ("Bear",),
    "horse": ("Horse",),
    "sheep": ("Sheep",),
    "chicken": ("Chicken",),
    "rabbit": ("Rabbit",),
    "family": ("House", "Person"),
    "friend": ("Person",),
    "baby": ("Boy", "Girl", "Person"),
    "mama": ("Woman",),
    "papa": ("Man",),
    "brother": ("Boy",),
    "sister": ("Girl",),
    "aunt": ("Woman",),
    "uncle": ("Man",),
    "grandma": ("Woman",),
    "grandpa": ("Man",),
    "cousin": ("Boy", "Girl"),
}


def map_word_to_label(word: str) -> Optional[str]:
    """Return the Open Images label for a word, if known."""
    word_lower = word.lower()
    candidates: List[str] = []

    override = LABEL_OVERRIDES.get(word_lower)
    if override:
        candidates.append(override)

    canonical = " ".join(part.capitalize() for part in word.split())
    if canonical:
        candidates.append(canonical)
    if canonical.endswith("s"):
        candidates.append(canonical.rstrip("s"))

    variant = LABEL_VARIANTS.get(word_lower)
    if variant:
        candidates.extend(variant)

    # Deduplicate while preserving order
    seen: set[str] = set()
    for candidate in candidates:
        if candidate in seen:
            continue
        seen.add(candidate)
        if candidate in OPENIMAGES_CLASSES:
            return candidate

    return None


def load_words(
    words: Sequence[str] | None,
    words_file: Path | None,
    sample_size: int,
    use_all_defaults: bool,
    seed: int | None,
) -> List[str]:
    """Return words from CLI, file, or default Swift sets."""
    collected: List[str] = []

    if words:
        collected.extend(w.strip() for w in words if w.strip())

    if words_file:
        with words_file.open("r", encoding="utf-8") as fh:
            for line in fh:
                candidate = line.strip()
                if candidate and not candidate.startswith("#"):
                    collected.append(candidate)

    if collected:
        return sorted(dict.fromkeys(collected), key=str.lower)

    defaults = unique_english_words()
    mappable_defaults = [word for word in defaults if map_word_to_label(word) is not None]

    if use_all_defaults:
        if not mappable_defaults:
            raise SystemExit("No default words map to Open Images classes. Add overrides first.")
        return mappable_defaults

    if sample_size <= 0:
        raise SystemExit("No words provided. Specify --words, --words-file or set --sample-size > 0.")

    if not mappable_defaults:
        raise SystemExit("Default word list has no Open Images matches. Add overrides or specify words explicitly.")

    sample_count = min(sample_size, len(mappable_defaults))
    rng = random.Random(seed)
    return sorted(rng.sample(mappable_defaults, sample_count), key=str.lower)


def ensure_output(base_dir: Path, word: str) -> Path:
    """Create the target directory for a given word."""
    word_dir = base_dir / word.replace(" ", "_")
    word_dir.mkdir(parents=True, exist_ok=True)
    return word_dir


def pick_label_field(dataset: fo.Dataset) -> str:
    """Pick a label-bearing field from the dataset."""
    schema = dataset.get_field_schema()
    for candidate in ("detections", "ground_truth", "positive_labels"):
        if candidate in schema:
            return candidate

    label_fields = dataset.list_label_fields()
    if label_fields:
        return label_fields[0]

    # Some Open Images splits expose positive_labels but do not mark it as a label field
    if "positive_labels" in schema:
        return "positive_labels"

    raise SystemExit("Dataset does not expose any label fields.")


def summarize_plan(words: Iterable[str], labels: Iterable[str], limit: int, output: Path) -> None:
    """Print a short summary of what will be downloaded."""
    words_list = list(words)
    labels_list = list(labels)
    print(f"\nPreparing Open Images download for {len(words_list)} word(s)")
    print(f"Images per word: {limit}")
    print(f"Estimated total: ~{limit * len(words_list)}")
    print(f"Output directory: {output}")
    print("\nWord → Label mapping:")
    for word, label in zip(words_list[:10], labels_list[:10]):
        print(f"  - {word:15s} → {label}")
    if len(words_list) > 10:
        print(f"  ... and {len(words_list) - 10} more")


def collect_samples(
    dataset: fo.Dataset,
    label_field: str,
    label: str,
    limit: int,
) -> List[fo.Sample]:
    """Return up to `limit` samples that contain the requested label."""
    results: List[fo.Sample] = []
    for sample in dataset:
        field_value = getattr(sample, label_field, None)
        if field_value is None:
            continue

        matched = False
        if isinstance(field_value, fol.Detections):
            matched = any(det.label == label for det in field_value.detections)
        elif isinstance(field_value, fol.Classifications):
            matched = any(cls.label == label for cls in field_value.classifications)
        elif isinstance(field_value, fol.Classification):
            matched = field_value.label == label
        elif isinstance(field_value, (list, tuple, set)):
            matched = label in field_value

        if not matched:
            continue

        results.append(sample)
        if len(results) >= limit:
            break

    return results


def download_images(
    words: Sequence[str],
    labels: Sequence[str],
    output: Path,
    limit: int,
    max_samples: int,
) -> None:
    """Download and export images grouped by word."""
    dataset = foz.load_zoo_dataset(
        "open-images-v7",
        split="validation",
        classes=list(set(labels)),
        max_samples=max_samples,
        shuffle=True,
        dataset_name=None,
        persistent=False,
    )

    try:
        if len(dataset) == 0:
            print("\n⚠️  No samples retrieved from the dataset. Nothing to export.")
            return

        label_field = pick_label_field(dataset)
        print(f"\nUsing label field: {label_field}")

        for word, label in zip(words, labels):
            print(f"\n→ {word} ({label})")
            word_dir = ensure_output(output, word)

            samples = collect_samples(dataset, label_field, label, limit)
            if not samples:
                print("  ⚠️  No samples found for this label. Skipping.")
                continue

            exported = 0
            for sample in samples:
                src = Path(sample.filepath)
                if not src.exists():
                    continue
                suffix = src.suffix or ".jpg"
                dst = word_dir / f"{word.replace(' ', '_').lower()}_{exported:03d}{suffix}"
                shutil.copy2(src, dst)
                exported += 1

            print(f"  ✓ Exported {exported} image(s) to {word_dir}")
    finally:
        dataset.delete()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Download Open Images photos grouped by vocabulary word",
    )
    parser.add_argument(
        "--words",
        nargs="+",
        help="Words to download (space separated)",
    )
    parser.add_argument(
        "--words-file",
        type=Path,
        help="Optional text file with one word per line",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=5,
        help="Images to export per word (default: 5)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "dev" / "output" / "openimages_photos",
        help="Where to store downloaded images",
    )
    parser.add_argument(
        "--max-samples",
        type=int,
        default=1000,
        help="Upper bound on samples fetched from the dataset (default: 1000)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print plan without downloading",
    )
    parser.add_argument(
        "-y",
        "--yes",
        action="store_true",
        help="Skip confirmation prompt",
    )
    parser.add_argument(
        "--sample-size",
        type=int,
        default=3,
        help="Randomly sample this many default words when none are provided (default: 3)",
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

    args = parser.parse_args()

    words = load_words(args.words, args.words_file, args.sample_size, args.all_defaults, args.seed)

    word_label_pairs: List[Tuple[str, str]] = []
    skipped: List[str] = []

    for word in words:
        label = map_word_to_label(word)
        if label is None:
            skipped.append(word)
        else:
            word_label_pairs.append((word, label))

    if not word_label_pairs:
        raise SystemExit("None of the requested words map to Open Images classes. Add overrides or choose different words.")

    if skipped:
        print("\n⚠️  Skipping words without Open Images classes:")
        for word in skipped:
            print(f"  - {word}")

    mapped_words = [pair[0] for pair in word_label_pairs]
    labels = [pair[1] for pair in word_label_pairs]

    summarize_plan(mapped_words, labels, args.limit, args.output)

    if args.dry_run:
        print("\nDry run complete. Run again without --dry-run to download images.")
        return

    if not args.yes:
        confirmation = input("\nDownload images now? (yes/no): ").strip().lower()
        if confirmation not in {"y", "yes"}:
            print("Cancelled.")
            return

    args.output.mkdir(parents=True, exist_ok=True)
    download_images(mapped_words, labels, args.output, args.limit, args.max_samples)
    print(f"\nAll done! Images saved under {args.output}")


if __name__ == "__main__":
    main()
