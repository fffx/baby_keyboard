# BabyKeyboardLock - Codebase Overview

BabyKeyboardLock is a macOS application that locks the keyboard to prevent accidental keypresses, designed especially for use with babies or toddlers. When locked, keyboard input is intercepted and, instead of normal system interaction, produces various customizable effects.

## Core Architecture

### Main Components

1. **EventHandler** (`EventHandler.swift`)
   - Singleton that manages keyboard event interception
   - Uses macOS accessibility API to capture system-wide keyboard events
   - Controls the locking/unlocking state
   - Routes captured events to the appropriate effect handler

2. **EventEffectHandler** (`EventEffectHandler.swift`)
   - Processes intercepted keyboard events
   - Implements various effects (sounds, words, etc.)
   - Manages word lists and translations

3. **UI Components** (`ContentView.swift`)
   - Main settings interface
   - Effect selection and configuration
   - Lock/unlock toggle

4. **Effect Types** (`LockEffect.swift`)
   - Defines available keyboard lock effects
   - Defines translation language options
   - Defines word set types

## Key Features

### 1. Keyboard Locking

The app uses macOS's accessibility APIs to intercept keyboard events system-wide:

- Implements a CGEvent tap to capture keystrokes
- Provides a keyboard shortcut (Ctrl+Option+U) to unlock
- Shows visual feedback when locked/unlocked

### 2. Effect System

When the keyboard is locked, keypresses trigger various effects:

- **None**: Just locks keyboard without effects
- **Confetti Cannon**: Visual confetti effect
- **Speak The Key**: Vocalizes the pressed key name
- **Speak A Key Word**: Speaks a word associated with the pressed key
- **Speak Random Word**: Speaks a random word from a custom list regardless of which key is pressed

### 3. Word Sets

For word-based effects, the app offers two types of word collections:

- **Random Short Words**: Built-in comprehensive dictionary of simple words organized by starting letter
- **Main Words**: Customizable set of core words

### 4. Translation System

Words can be spoken in multiple languages:

- Supports English, French, Russian, German, Spanish, Italian, Japanese, and Chinese
- Translates words automatically using built-in dictionaries
- In "Speak Random Word" mode, speaks both English and translation

### 5. Customization

Users can customize various aspects:

- Edit the list of words for "Main Words" set
- Edit the random words list for "Speak Random Word" mode
- Select preferred translation language
- Choose to lock keyboard on application launch

## Data Management

- Uses `UserDefaults` to store settings and preferences
- Custom word lists stored as encoded JSON data
- Implements `Codable` for serialization/deserialization

## User Interaction Flow

1. User launches the app
2. Toggles the "Lock Keyboard" switch
3. System-wide keyboard events are intercepted
4. Effects are applied based on user settings
5. User can unlock with the designated shortcut

## Key Classes in Detail

### `EventHandler`

- Handles system-wide keyboard event capture
- Manages permission requests for accessibility features
- Contains logic for the keyboard shortcut to unlock
- Throttles event processing to prevent rapid-fire effects

### `EventEffectHandler`

- Contains dictionaries of words for each initial letter
- Maintains translation dictionaries for multiple languages
- Implements word selection logic for different modes
- Handles text-to-speech via AVSpeechSynthesizer

### `LockEffect` and related enums

- Defines the available effect types
- Provides localized strings for UI display
- Structures the application's feature set

### `RandomWordList` and `CustomWordSetsManager`

- Manage specialized word collections
- Support custom user-defined word sets
- Handle persistence and retrieval of word data
- Notify the UI of changes through NotificationCenter

## Technical Implementation Details

1. **System Integration**
   - Uses Carbon and ApplicationServices to tap into macOS event system
   - Properly handles permissions through macOS accessibility services
   - Implements proper event lifecycle management

2. **Thread Management**
   - Uses run loops and async dispatching for event processing
   - Prevents UI blocking during event handling

3. **Localization Support**
   - Implements NSLocalizedString for UI elements
   - Stores translations in Localizable.xcstrings

4. **User Interface**
   - SwiftUI-based interface
   - Reactive design using @Published properties and ObservableObject
   - Sheet-based editors for word list customization

5. **Event Processing Pipeline**
   - Event capture → Effect selection → Processing → Output
   - Properly handles event passing/blocking 