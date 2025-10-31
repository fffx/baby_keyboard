# Flashcard Image Generation Scripts

## Quick Start

Generate flashcard images for all words in the BabyKeyboardLock app.

### Current Status
- **Total Words:** 145 unique words across 14 word sets
- **Styles:** crayon, doodle, pencil, simple (4 styles)
- **Missing Images:** ~546 images needed
- **Estimated Cost:** ~$21.84 (using DALL-E 3 @ $0.04/image)

### Prerequisites

```bash
# Install dependencies
pip install openai loguru pydantic litellm

# Set API key
export CALMMAGE_OPENAI_API_KEY="your-key-here"
```

### Usage

```bash
# Preview generation plan (no cost)
python3 generate_flashcard_images.py --dry-run

# Generate specific style
python3 generate_flashcard_images.py --style crayon

# Test with limited images
python3 generate_flashcard_images.py --limit 10

# Generate specific words
python3 generate_flashcard_images.py --words apple banana cat

# Generate all missing images
python3 generate_flashcard_images.py
```

### Output Structure
```
dev/Resources/FlashcardImages/
├── crayon/
│   ├── crayon_apple.png
│   ├── crayon_banana.png
│   └── ...
├── doodle/
│   ├── doodle_apple.png
│   └── ...
├── pencil/
│   ├── pencil_apple.png
│   └── ...
└── simple/
    ├── simple_apple.png
    └── ...
```

## Script Details

### generate_flashcard_images.py

**What it does:**
1. Extracts all unique words from word sets
2. Checks which images already exist
3. Generates missing images with AI
4. Saves with correct naming convention
5. Tracks progress and costs

**Features:**
- Cost estimation before generation
- Dry-run mode for planning
- Style-specific generation
- Progress tracking
- Rate limiting (1 sec between requests)
- Error handling and retry logic

### Word Sets Included

**Starter (10 words):** mama, papa, baby, milk, water, yes, no, bye, hi, love

**Animals (25 words):** cat, dog, bird, fish, cow, duck, pig, rabbit, mouse, bear, horse, sheep, chicken, lion, tiger, elephant, giraffe, monkey, zebra, frog, butterfly, snake, turtle, penguin, owl

**Food (25 words):** apple, banana, bread, cookie, juice, egg, cheese, cake, soup, tea, orange, grape, strawberry, watermelon, carrot, potato, tomato, cucumber, ice cream, pizza, pasta, rice, meat, chicken, sandwich

**Body Parts (12 words):** head, eye, nose, mouth, ear, hand, finger, leg, foot, belly, hair, tooth

**Colors (11 words):** red, blue, green, yellow, orange, purple, pink, brown, black, white, gray

**Actions (22 words):** eat, drink, sleep, walk, run, jump, play, sit, stand, look, dance, sing, read, draw, write, clap, wave, hug, kiss, laugh, cry, smile

**Toys (12 words):** ball, doll, teddy bear, car, train, bike, block, puzzle, book, swing, slide, drum

**Nature (12 words):** sun, moon, star, cloud, rain, snow, tree, flower, grass, water, sky, wind

**Vehicles (10 words):** car, bus, truck, train, plane, helicopter, boat, ship, rocket, bicycle

**Family (10 words):** grandma, grandpa, brother, sister, aunt, uncle, cousin, friend, family, home

## Image Styles

**Crayon:** Children's crayon drawing style, colorful, simple shapes, waxy texture

**Doodle:** Simple hand-drawn doodle style, black and white line art, playful

**Pencil:** Pencil sketch style, gentle shading, soft lines, artistic

**Simple:** Minimalist simple flat design, clean shapes, educational illustration

## Troubleshooting

**"No module named 'loguru'"**
```bash
pip install loguru pydantic litellm openai
```

**"API key not found"**
```bash
export CALMMAGE_OPENAI_API_KEY="sk-..."
```

**Images not appearing in Xcode**
1. Copy generated images to Xcode project
2. Add to Assets.xcassets or project resources
3. Ensure naming matches: `{style}_{word}.png`

## Next Steps

1. **Test:** Run with `--dry-run --limit 5`
2. **Generate sample:** `--limit 10` to test quality
3. **Review:** Check generated images meet requirements
4. **Full run:** Generate all 546 images
5. **Integrate:** Copy to Xcode project

## References

- Strategy Doc: `/dev/notes/image_generation_strategy.md`
- Swift Implementation: `/BabyKeyboardLock/utils/FlashcardStyle.swift`
- Word Sets: `/BabyKeyboardLock/utils/RandomWordList.swift`
