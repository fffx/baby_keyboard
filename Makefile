.PHONY: deploy update clean archive export install fix-signature
.PHONY: test-images test-quickdraw test-generate download-quickdraw generate-all-images

# Main target - build and deploy the app
deploy: archive export install
	@echo "✅ BabyKeyboardLock deployed successfully to /Applications/"

# Alias for deploy - update the installed app
update: deploy

# Clean build artifacts
clean:
	@./scripts/clean.sh

# Build archive
archive: clean
	@./scripts/archive.sh

# Export archive
export:
	@./scripts/export.sh

# Install to Applications folder
install:
	@./scripts/install.sh

# Fix signature issues (resets accessibility permissions!)
fix-signature:
	@./scripts/fix-signature.sh

# ============== Image Generation Commands ==============

# Test both image generation methods (3 test images each)
test-images:
	@echo "🧪 Testing image generation methods..."
	@./scripts/test_image_generation.sh

# Test Quick Draw dataset download (3 categories)
test-quickdraw:
	@echo "🧪 Testing Quick Draw download (3 categories)..."
	@uv run python scripts/download_quickdraw.py \
		--categories cat dog apple \
		--extract-samples 5 \
		--output ./test_quickdraw

# Test nano-banana image generation (3 images)
test-generate:
	@echo "🧪 Testing nano-banana generation (3 images)..."
	@uv run python scripts/generate_with_nano_banana.py \
		--words cat dog apple \
		--style crayon \
		--model nano-banana \
		--limit 3

# Download full Quick Draw dataset (all baby-friendly categories)
download-quickdraw:
	@echo "📥 Downloading Quick Draw dataset..."
	@uv run python scripts/download_quickdraw.py \
		--extract-samples 10 \
		--output ./quickdraw_images

# Generate all missing flashcard images with nano-banana
generate-all-images:
	@echo "🎨 Generating all missing flashcard images..."
	@uv run python scripts/generate_with_nano_banana.py \
		--model nano-banana

# Generate specific style only
generate-crayon:
	@uv run python scripts/generate_with_nano_banana.py --style crayon --model nano-banana

generate-doodle:
	@uv run python scripts/generate_with_nano_banana.py --style doodle --model nano-banana

generate-pencil:
	@uv run python scripts/generate_with_nano_banana.py --style pencil --model nano-banana

generate-simple:
	@uv run python scripts/generate_with_nano_banana.py --style simple --model nano-banana
