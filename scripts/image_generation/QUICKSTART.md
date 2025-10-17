# Quick Start: Generate Flashcard Images

**Task:** `3286692c` - Add more images for baby keyboard flashcards

## TL;DR

```bash
# 1. Install dependencies
pip install openai requests

# 2. Set API key
export OPENAI_API_KEY="sk-your-key-here"

# 3. Preview (free)
python3 dev/scripts/generate_with_dalle.py --dry-run --limit 10

# 4. Generate sample (costs ~$0.40 for 10 images)
python3 dev/scripts/generate_with_dalle.py --limit 10

# 5. Generate all (costs ~$21.84 for 546 images)
python3 dev/scripts/generate_with_dalle.py
```

## What Gets Generated

**145 unique words** × **4 styles** = **546 images**

### Styles
- 🖍️ **Crayon** - Colorful children's crayon drawing
- ✏️ **Doodle** - Simple black & white line art
- ✏️ **Pencil** - Soft pencil sketch with shading
- 🎨 **Simple** - Minimalist flat design

### Word Categories
- Starter (10): mama, papa, baby, milk, water...
- Animals (25): cat, dog, bird, fish, lion...
- Food (25): apple, banana, bread, pizza...
- Body Parts (12): head, eye, nose, hand...
- Colors (11): red, blue, green, yellow...
- Actions (22): eat, drink, sleep, run...
- Toys (12): ball, doll, car, puzzle...
- Nature (12): sun, moon, star, tree...
- Vehicles (10): car, bus, train, plane...
- Family (10): grandma, grandpa, brother...

## Cost Breakdown

| Option | Images | Cost (DALL-E 3) | Time |
|--------|--------|-----------------|------|
| Test (10) | 10 | $0.40 | ~30 sec |
| Priority (40) | 40 | $1.60 | ~2 min |
| Easy Level (200) | 200 | $8.00 | ~7 min |
| **Full Set** | **546** | **$21.84** | **~18 min** |

*Based on DALL-E 3 pricing: $0.04 per 1024×1024 image*

## Alternative Options

### Option 1: Free Image Collections
**Pros:** Free, pre-made
**Cons:** Inconsistent, time-consuming
**Sources:** OpenGameArt, Flaticon, Google Quick Draw

### Option 2: Commission Artist
**Cost:** $300-1500 for full set
**Pros:** Custom style, high quality
**Cons:** Expensive, slow

### Option 3: Hybrid
1. Free images for common objects
2. AI for abstract concepts
3. Commission for specialty sets

## Generated Image Locations

```
dev/Resources/FlashcardImages/
├── crayon/
│   ├── crayon_apple.png
│   ├── crayon_banana.png
│   ├── crayon_cat.png
│   └── ... (145 total)
├── doodle/
│   ├── doodle_apple.png
│   └── ... (145 total)
├── pencil/
│   ├── pencil_apple.png
│   └── ... (145 total)
└── simple/
    ├── simple_apple.png
    └── ... (145 total)
```

## Integration Steps

After generation:

1. **Review images** - Check quality and appropriateness
2. **Copy to Xcode** - Add to Assets.xcassets or Resources
3. **Build & test** - Verify images load correctly
4. **Adjust prompts** - If needed, regenerate specific images

## Troubleshooting

**Error: "No module named 'openai'"**
```bash
pip install openai requests
```

**Error: "API key not found"**
```bash
# Try one of these:
export OPENAI_API_KEY="sk-..."
export CALMMAGE_OPENAI_API_KEY="sk-..."
```

**Images not loading in app**
- Check filename matches: `{style}_{word}.png`
- Verify in correct directory
- Rebuild Xcode project

## Advanced Usage

### Generate Specific Style
```bash
python3 dev/scripts/generate_with_dalle.py --style crayon
```

### Generate Specific Words
```bash
python3 dev/scripts/generate_with_dalle.py --words apple banana cat dog
```

### Custom Delay (rate limiting)
```bash
python3 dev/scripts/generate_with_dalle.py --delay 3.0
```

### Test Without API Calls
```bash
python3 dev/scripts/generate_with_dalle.py --dry-run
```

## Files Created

| File | Purpose |
|------|---------|
| `generate_flashcard_images.py` | Base generation framework |
| `generate_with_dalle.py` | DALL-E 3 integration (production) |
| `README.md` | Script documentation |
| `QUICKSTART.md` | This file |
| `/dev/notes/image_generation_strategy.md` | Full strategy guide |

## Resources

- **Strategy Doc:** `/dev/notes/image_generation_strategy.md`
- **Swift Code:** `/BabyKeyboardLock/utils/FlashcardStyle.swift`
- **Word Sets:** `/BabyKeyboardLock/utils/RandomWordList.swift`
- **OpenAI Pricing:** https://openai.com/pricing

## Next Steps

1. ✅ Scripts created and tested
2. ⏳ Set up OpenAI API key
3. ⏳ Run test generation (10 images)
4. ⏳ Review quality
5. ⏳ Generate full set (546 images)
6. ⏳ Integrate into Xcode project

**Ready to start?** Run the dry-run command to preview! 🚀
