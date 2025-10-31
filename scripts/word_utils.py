"""Utilities for reading Baby Keyboard word lists from Swift sources."""

from __future__ import annotations

import random
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SWIFT_PATH = PROJECT_ROOT / "BabyKeyboardLock" / "utils" / "RandomWordList.swift"


@dataclass(frozen=True)
class WordEntry:
    english: str
    translation: str


@dataclass(frozen=True)
class WordSet:
    name: str
    words: Tuple[WordEntry, ...]


def _extract_bracket_block(source: str, start_index: int) -> Tuple[str, int]:
    """Return substring inside matching brackets and index of the closing bracket."""
    depth = 0
    for idx in range(start_index, len(source)):
        char = source[idx]
        if char == "[":
            depth += 1
        elif char == "]":
            depth -= 1
            if depth == 0:
                return source[start_index + 1 : idx], idx
    raise ValueError("Unmatched bracket while parsing Swift word sets")


def load_word_sets(swift_path: Path | None = None) -> List[WordSet]:
    """Parse RandomWordList.swift and return default word sets."""
    path = swift_path or DEFAULT_SWIFT_PATH
    raw = path.read_text(encoding="utf-8")

    set_pattern = re.compile(r'RandomWordSet\(\s*name:\s*"([^"]+)"[^[]*\[', re.MULTILINE)
    word_pattern = re.compile(
        r'RandomWord\(\s*english:\s*"([^"]+)"\s*,\s*translation:\s*"([^"]*)"\s*\)',
        re.MULTILINE,
    )

    word_sets: List[WordSet] = []

    for match in set_pattern.finditer(raw):
        name = match.group(1)
        bracket_pos = raw.find("[", match.end() - 1)
        if bracket_pos == -1:
            continue
        block, _ = _extract_bracket_block(raw, bracket_pos)

        words = [
            WordEntry(english=english.strip(), translation=translation.strip())
            for english, translation in word_pattern.findall(block)
        ]

        word_sets.append(WordSet(name=name, words=tuple(words)))

    if not word_sets:
        raise ValueError(f"No word sets parsed from {path}")

    return word_sets


def all_word_entries(swift_path: Path | None = None) -> List[WordEntry]:
    """Return flattened list of word entries (with duplicates)."""
    entries: List[WordEntry] = []
    for word_set in load_word_sets(swift_path):
        entries.extend(word_set.words)
    return entries


def unique_english_words(swift_path: Path | None = None) -> List[str]:
    """Return sorted unique english words from all sets."""
    unique = {entry.english for entry in all_word_entries(swift_path)}
    return sorted(unique, key=str.lower)


def english_to_translation_map(swift_path: Path | None = None) -> Dict[str, str]:
    """Return mapping of english word -> translation."""
    mapping: Dict[str, str] = {}
    for entry in all_word_entries(swift_path):
        mapping.setdefault(entry.english, entry.translation)
    return mapping


def sample_english_words(
    count: int,
    swift_path: Path | None = None,
    seed: int | None = None,
) -> List[str]:
    """Return a random sample of unique english words."""
    words = unique_english_words(swift_path)
    if count >= len(words):
        return words
    rng = random.Random(seed)
    return rng.sample(words, count)


def describe_word_sets(swift_path: Path | None = None) -> List[Tuple[str, int]]:
    """Return summary tuples of (set name, word count)."""
    return [(word_set.name, len(word_set.words)) for word_set in load_word_sets(swift_path)]
