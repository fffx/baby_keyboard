.PHONY: generate-images download-openimages

PYTHON := .venv/bin/python3
.PHONY: test-openimage run-openimage test-gemini run-gemini
.PHONY: list-words
.PHONY: deploy update clean archive export install

# Compose shared flag helpers
WORDS_FLAG := $(if $(strip $(WORDS)),--words $(WORDS),)
WORDS_FILE_FLAG := $(if $(strip $(WORDS_FILE)),--words-file $(WORDS_FILE),)
OUTPUT_FLAG := $(if $(strip $(OUTPUT)),--output $(OUTPUT),)
MODEL_FLAG := $(if $(strip $(MODEL)),--model $(MODEL),)
SIZE_FLAG := $(if $(strip $(SIZE)),--size $(SIZE),)
MAX_CONCURRENT_FLAG := $(if $(strip $(MAX_CONCURRENT)),--max-concurrent $(MAX_CONCURRENT),)
SAMPLE_SIZE_FLAG := $(if $(strip $(SAMPLE_SIZE)),--sample-size $(SAMPLE_SIZE),)
SEED_FLAG := $(if $(strip $(SEED)),--seed $(SEED),)
ALL_DEFAULTS_FLAG := $(if $(strip $(ALL_DEFAULTS)),--all-defaults,)

# Image generator specific flags
STYLE_FLAG := $(if $(strip $(STYLE)),--style $(STYLE),)
STYLE_PROMPT_FLAG := $(if $(strip $(STYLE_PROMPT)),--style-prompt "$(STYLE_PROMPT)",)

# Open Images specific flags
LIMIT_FLAG := $(if $(strip $(LIMIT)),--limit $(LIMIT),)
MAX_SAMPLES_FLAG := $(if $(strip $(MAX_SAMPLES)),--max-samples $(MAX_SAMPLES),)

generate-images:
	$(PYTHON) scripts/generate_images.py \
		$(WORDS_FLAG) \
		$(WORDS_FILE_FLAG) \
		$(SAMPLE_SIZE_FLAG) \
		$(SEED_FLAG) \
		$(ALL_DEFAULTS_FLAG) \
		$(STYLE_FLAG) \
		$(STYLE_PROMPT_FLAG) \
		$(OUTPUT_FLAG) \
		$(MODEL_FLAG) \
		$(SIZE_FLAG) \
		$(MAX_CONCURRENT_FLAG) \
		$(ARGS)

download-openimages:
	$(PYTHON) scripts/download_openimages.py \
		$(WORDS_FLAG) \
		$(WORDS_FILE_FLAG) \
		$(OUTPUT_FLAG) \
		$(SAMPLE_SIZE_FLAG) \
		$(SEED_FLAG) \
		$(ALL_DEFAULTS_FLAG) \
		$(LIMIT_FLAG) \
		$(MAX_SAMPLES_FLAG) \
		$(ARGS)

test-openimage:
	$(MAKE) --no-print-directory download-openimages SAMPLE_SIZE=2 LIMIT=2 MAX_SAMPLES=40 ARGS="--yes"

run-openimage: download-openimages

test-gemini:
	printf 'yes\n' | $(MAKE) --no-print-directory generate-images SAMPLE_SIZE=2 MAX_CONCURRENT=2

run-gemini: generate-images

list-words:
	uv run python -m scripts.list_words


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
