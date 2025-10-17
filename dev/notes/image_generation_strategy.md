# Image Generation Strategy for BabyKeyboardLock

**Task Key:** `3286692c`

## Current Status

### Existing Images
- **Location:** `/dev/Resources/FlashcardImages/`
- **Styles:** 4 (crayon, doodle, pencil, simple)
- **Naming Convention:** `{style}_{word}.png` (e.g., `crayon_apple.png`)
- **Current Coverage:** ~15 words with images out of 145 total unique words

### Word Sets
The project has 14 word sets with varying difficulty levels:
- **Starter Level (6m-1y):** 10 words (mama, papa, baby, milk, water, etc.)
- **Easy Level (1-2y):** Animals, Food, Body Parts, Colors, Actions (~50 words)
- **Medium Level (2-3y):** More animals, Food, Toys, Nature, Actions (~60 words)
- **Advanced Level (3+y):** Vehicles, Family (~20 words)
- **Total Unique Words:** 145

### Gap Analysis
- **Images Needed:** 546 images (145 words × 4 styles - existing images)
- **Estimated Cost (DALL-E 3):** ~$21.84 ($0.04 per image)

## Strategy Options

### Option 1: AI Image Generation (Recommended)
**Pros:**
- Consistent style across all images
- Complete control over content
- Child-friendly and educational focus
- Fast bulk generation

**Cons:**
- Cost (~$22 for full set)
- Requires API setup (DALL-E, Stable Diffusion, or similar)

**Implementation:**
Use the provided script at `/dev/scripts/generate_flashcard_images.py`

```bash
# Preview what will be generated
python3 dev/scripts/generate_flashcard_images.py --dry-run

# Generate a specific style
python3 dev/scripts/generate_flashcard_images.py --style crayon

# Generate specific words
python3 dev/scripts/generate_flashcard_images.py --words apple banana cat

# Generate all missing images
python3 dev/scripts/generate_flashcard_images.py
```

### Option 2: Free Online Collections
**Sources to Explore:**
1. **OpenGameArt.org** - Creative Commons game art
2. **Google Quick Draw Dataset** - Simple doodles (open dataset)
3. **Flaticon** - Icon collections (check licenses, may require attribution)
4. **Wikimedia Commons** - Some educational flashcard collections
5. **Noun Project** - Icon sets (check licenses)

**Pros:**
- Free or low-cost
- Pre-made content

**Cons:**
- Inconsistent styles
- Licensing complexity
- May not match our exact style requirements
- Time-consuming to find and curate

### Option 3: Hybrid Approach
1. Use free collections for common words (animals, objects)
2. Generate custom images for abstract concepts (actions, emotions, colors)
3. Commission artist for specific style sets

## Implementation Guide

### Setup Requirements

#### 1. Install Dependencies
```bash
# Install calmlib LLM utils (if not already installed)
cd ~/calmmage/calmlib
pip install -r requirements.txt

# Or install required packages directly
pip install openai anthropic loguru pydantic litellm
```

#### 2. Configure API Keys
Set up environment variables for image generation:
```bash
# For OpenAI DALL-E
export CALMMAGE_OPENAI_API_KEY="your-key-here"

# Alternative: Anthropic Claude (for prompt refinement)
export CALMMAGE_ANTHROPIC_API_KEY="your-key-here"
```

#### 3. Enable Image Generation in Script
The current script has placeholder for image generation. To complete:

1. Uncomment/implement image generation API calls in `generate_image()` function
2. Add image download and save logic
3. Test with a small batch first (`--limit 10`)

### Execution Plan

#### Phase 1: Priority Words (Starter + Basic)
- **Words:** 15-20 most common words
- **Styles:** All 4 styles
- **Cost:** ~$3-4
- **Command:**
  ```bash
  python3 dev/scripts/generate_flashcard_images.py \
    --words mama papa baby cat dog arm leg eye nose mouth \
    --limit 40
  ```

#### Phase 2: Easy Level Words
- **Words:** ~50 words
- **Styles:** All 4 styles
- **Cost:** ~$8
- **Command:**
  ```bash
  python3 dev/scripts/generate_flashcard_images.py --style crayon
  python3 dev/scripts/generate_flashcard_images.py --style doodle
  # etc.
  ```

#### Phase 3: Medium + Advanced Words
- **Words:** ~80 words
- **Styles:** All 4 styles
- **Cost:** ~$13
- **Command:**
  ```bash
  python3 dev/scripts/generate_flashcard_images.py
  ```

### Quality Control

**Review Checklist:**
- [ ] Image is child-friendly (no scary/inappropriate content)
- [ ] Subject is clearly recognizable
- [ ] Style matches the category (crayon/doodle/pencil/simple)
- [ ] No text appears in the image
- [ ] Square aspect ratio (1:1)
- [ ] High contrast and visibility
- [ ] Appropriate for age group (1-3 years)

**Testing:**
1. Generate sample batch (5-10 images)
2. Review quality and consistency
3. Adjust prompts if needed
4. Run full generation

## Alternative: Manual Image Creation

### Tools for Manual Creation
1. **Procreate** (iPad) - Great for stylized drawings
2. **Adobe Illustrator** - Vector graphics for simple style
3. **Canva** - Quick templates for educational images
4. **Krita** - Free digital painting tool

### Outsourcing Options
1. **Fiverr** - Commission artists for style-specific sets
2. **Upwork** - Find illustrator for bulk creation
3. **99designs** - Contest for style development
4. **Local art students** - Cost-effective, support students

**Estimated Cost for Commissioned Work:**
- Per image: $2-10 (depending on complexity)
- Full set: $300-1500

## Resources for Free Images

### Recommended Sites
1. **OpenClipart** - https://openclipart.org/
2. **Pixabay** - https://pixabay.com/ (vectors)
3. **Pexels** - https://www.pexels.com/
4. **Unsplash** - https://unsplash.com/
5. **Freepik** - https://www.freepik.com/ (requires attribution)

### Educational Resources
1. **TEAL Center Flashcards** - Check for CC-licensed sets
2. **Open Educational Resources (OER)** - Search for early childhood materials
3. **Wikipedia Commons Education Category**

## Next Steps

1. **Decide on approach:** AI generation vs. manual vs. hybrid
2. **Set budget:** Allocate funds if using paid services
3. **Test generation:** Run script with `--dry-run` and small batch
4. **Quality review:** Check first batch before full generation
5. **Integration:** Copy generated images to Xcode project
6. **Update code:** Ensure FlashcardStyle.swift handles all new words

## Script Usage Examples

```bash
# Check what needs to be generated
python3 dev/scripts/generate_flashcard_images.py --dry-run

# Generate only missing crayon style images
python3 dev/scripts/generate_flashcard_images.py --style crayon

# Test with just 5 images
python3 dev/scripts/generate_flashcard_images.py --limit 5

# Generate specific words across all styles
python3 dev/scripts/generate_flashcard_images.py \
  --words apple banana orange grape

# Generate everything (546 images)
python3 dev/scripts/generate_flashcard_images.py
```

## Notes

- The script includes cost estimation before generation
- Progress is shown for each image generated
- Rate limiting is built in (1 second between requests)
- Failed generations are tracked separately
- Images are saved with correct naming convention

## TODO

- [ ] Integrate actual image generation API (DALL-E/Stable Diffusion)
- [ ] Add image quality validation
- [ ] Implement MongoDB tracking for large batches
- [ ] Add resume functionality for interrupted generations
- [ ] Create variation support (multiple versions per word)
- [ ] Add batch review UI for quality control
