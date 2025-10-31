#!/usr/bin/env python3
"""Print the unique Baby Keyboard dictionary words."""

from scripts.word_utils import unique_english_words


def main() -> None:
    """Emit each word on its own line."""
    for word in unique_english_words():
        print(word)


if __name__ == "__main__":
    main()
