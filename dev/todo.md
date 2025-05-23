- [ ] Optimize performance 
  - [x] - remove tracking when inactive - DONE: event tap passes through all events immediately when unlocked
  - [ ] something else?
  - [ ] fix lag? why is the app slow? 


# Key features
- [ ] Add pictures for all words
- [ ] Simplify UI and settings menus, UX. Add clarity



- [ ] auto-detect cyrillic letter inputs and ... process somehow. o
  - [ ] add vocabularies for all main languages as well - allow to select / auto-use that on different layout
  - [ ] Add an option to change main language. Add collections for all main languages.  (and add for corresponding starting letter - e.g. Katze - for K)

- [ ] Bugfix - in 'random word' mode the translation language is ignored - it always shows russian version with the english one. 

- [ ] add new visual effects
  - [ ] For all our effects, would be cool if we could make them appear on screen roughly at the same place where the clicked key is on keyboard..  let's add to todo list and add a checkbox (location -> random / keyboard) later

- [ ] add a button to select a random effect

- [ ] fix bug with voice services and translations
  - [ ] fix "Error reading languages in for local resources" error
  - [ ] resolve failed queries for "com.apple.MobileAsset.VoiceServices.GryphonVoice"
  - [ ] resolve failed queries for "com.apple.MobileAsset.VoiceServicesVocalizerVoice"
  - [ ] check voice language availability before usage
  - [ ] setup instructions - how to add more voices? 
- [ ] pick a voice for word voiceover

Done
- [x] Use personal voice - add checkbox, check if created
- [x] add a comprehensive overview of the code in CLAUDE.md
- [x] add more effects? generate a list of ideas - other than confetti.
- [x] add custom word sets
  - [x] fix warnings
  - [x] rework to select word set by default
  - [x] add words for all letters
- [x] add new mode - speak random word
- [x] in 'speak a word' mode - show the word and its tranlsations - in caps - on a white background
  - [x] add configurable timing for word display on screen with slider (1-10 seconds)
  - [x] fix display duration for word display to ensure words disappear after configured time
- [x] add a custom field for baby's name

# Content Display Optimization Issues (from log analysis)

## High Priority - Window/Layout Issues
- [x] Fix excessive window height readjustments (FIXED: added debouncing and larger thresholds)
- [ ] Resolve layout constraint conflicts in status bar (NSLayoutConstraint conflicts)
- [x] Streamline `updateWindowForHeight` method to avoid size mismatch cycles (FIXED: improved WindowManager)
- [x] Fix "Size mismatch, trying again with animation" infinite loops (FIXED: better thresholds)
- [x] Debounce height calculations in ContentView - too many "Content height changed to" calls (FIXED: increased threshold to 10px)
- [x] Remove duplicate window sizing logic between ContentView and GeometryReader (FIXED: consolidated in WindowManager)

## Medium Priority - Performance & Redundancy
- [x] Optimize throttling messages - reduce verbose "Throttled >>>>> timeSinceLastEvent" logging (FIXED: 2 decimal precision)
- [x] Consolidate multiple "Resetting all visual effects" calls (FIXED: only log when actually resetting)
- [x] Fix picker selection validation ("Picker: the selection X is invalid") (FIXED: proper category-effect matching)
- [x] Prevent duplicate event handler initialization (FIXED: voice cache check)
- [x] Cache window references instead of searching NSApp.windows repeatedly (FIXED: WindowManager caches window)
- [ ] Optimize fullscreen window creation - created at startup but constantly resized

## Low Priority - Audio System Issues
- [x] Fix "Cannot use AVSpeechSynthesizerBufferCallback with Personal Voices" warnings (FIXED: voice caching & throttling)
- [x] Handle voice service asset query failures gracefully (FIXED: cached voice discovery reduces queries)
- [ ] Reduce "Error reading languages in for local resources" frequency  
- [x] Fix "Already playing" NSSound warnings (FIXED: improved sound pool with stop/reuse logic)
- [x] Optimize sound pool management in AnimationView (FIXED: larger pool with reuse strategy)
- [x] Fix crash handler proxy errors on each keypress (PARTIAL: improved speech throttling, gentler audio stops, pending speech tracking)

## Code Structure Improvements
- [ ] Move window management logic into dedicated WindowManager class
- [ ] Create consistent height calculation strategy across all views
- [ ] Implement proper SwiftUI state management to prevent layout fighting
- [ ] Add window frame caching to avoid repeated calculations
- [ ] Create unified visual effects coordinator to prevent state conflicts