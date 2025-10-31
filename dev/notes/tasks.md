- a
    - `key: 441b4ef3`
    - `cue: My PC turns into a heater when I run my app..`
    - Generate audio samples with TTS and cache on disk to prevent running heavy AI model every time instead of just playing the sound
    - Add 'refresh cache' button in Settings
- b
    - `key: 78983d50`
    Test the flashcard display for game mode
- c
    - `key: 8938ae62`
    Improve game mode - remove per-letter sound, Allow all words simultaneousl
- d
    - `key: 81e9cb8c`
    - Initial request: I've ran make images-main - first step - but where are the files?
    - Latest: what? do uv add..
- e
    - `key: bd515a4e`
    - Simplify our window resize logic as much as possible because it's causing issues
    - Allow macOS to handle window sizes, scrolling and positions automatically
    - Experiment in a separate branch
- f
    - `key: b394d43b`
    - Use simple color images if the word selected is a color
- g
    - `key: 4abc703d`
    - `cue: Couldn't get a specific word - mama - to appear at all`
    - Rework random into pseudo-random that balances probabilities into a more even shuffle
- h
    - `key: c0e2f3af`
    generate images with nano-banana using script
- i
    - `key: ddd1a65b`
    Publish calmlib, install and download quick draw images
- j
    - `key: 490a0894`
      Load images from user folder instead of including resources in the package. Bonus: Auto-generate words for images and use that set in text
- k
    - `key: 8e21dce0`
    - Gamify keyboard locker somehow
    - Idea 1: Add a new mode, where the baby has to type the word correctly for it to appear on the screen and be
      pronounced
    - When baby types the letters correctly - make them appear on screen (e.g. if she types 'M' - show 'M', then add
      'A' etc.). Allow any words from selected word sets.
      Some nice animation when the word is completed correctly
    - Add a setting checkbox "reset on error".
- l
    - `key: 20234a42`
    - Make it a website
- m
    - `key: 8d4d24da`
    - `cue: I tried to deploy on Anna's macbook using make deploy, and it failed saying it can't export archive because it misses the certificate. The main question is do i create a new one or copy this one?`
    - Figure out how to deploy on another machine - missing certificate
    Build description signature: c6f264918b4db5acd581c2181fb6fac3
    Build description path: /Users/annalav/Library/Developer/Xcode/DerivedData/BabyKeyboardLock-bgubpirqszsziihdvtozqvgxmqja/Build/Intermediates.noindex/ArchiveIntermediates/BabyKeyboardLock/IntermediateBuildFilesPath/XCBuildData/c6f264918b4db5acd581c2181fb6fac3.xcbuilddata
    /Users/annalav/Documents/GitHub/baby_keyboard/BabyKeyboardLock.xcodeproj: error: No signing certificate "Mac Development" found: No "Mac Development" signing certificate matching team ID "5XCYR4LUMD" with a private key was found. (in target 'BabyKeyboardLock' from project 'BabyKeyboardLock')
    a
## Done
- [x] n
    - `key: 3286692c`
    - Add more images
    - use planned llm utils to bulk-generate the set (look at ~/calmmage/experiments/llm/dev/notes)
    - also, first, think if / where can i get nice image collections for basic words on the web
    - there should be default 'alphabet' images, right?
    - also there should probably some nice art projects with stylized alphabet images
      (i mean not only alphabet of course - but in general basic simple words)
- [x] o
    - `key: 38b988cb`
    - Bugfix baby image selector
        - Doesn't work in prod
        - Issue occurs after deployment (make deploy)
        - Investigate root cause of production failure
- [x] p
    - `key: f9b55897`
    - Add 'mother' and 'father' image selectors
    - All basic family members
    - Arbitrary images with arbitrary words
    - Like the custom dictionary feature that we have
    a
- [x] q
    - `key: d803f29f`
    - Cancelled (2025-10-26 05:17): There's no 'person' api support on macbook
    - Can we use apple photos people for 'mother' and 'baby'?
    - I want to wire like specific persons
        - by name?
        - Or how?
        - I guess they have some contact id, but i don't want to have to enter that
    - Maybe search + select
    - Or, for now, if there's a single person in contacts with that name
        - use that
        - else
            - raise notimpelented
- [x] r
    - `key: 8884e924`
    - `cue: The settings don't fit the screen on Anna's monitor, and can't be scrolled. Also, I'm adding new settings`
    - How do I rework settings menu to contain less items
    - Move additional settings to a separate window
