import SwiftUI
import Combine

struct WordDisplayView: View {
    @ObservedObject var eventHandler: EventHandler = EventHandler.shared
    @State private var word: String = ""
    @State private var translation: String = ""
    @State private var showWord: Bool = false
    @AppStorage("wordDisplayDuration") private var wordDisplayDuration: Double = DEFAULT_WORD_DISPLAY_DURATION
    @AppStorage("showFlashcards") private var showFlashcards: Bool = false
    @AppStorage("flashcardStyle") private var flashcardStyle: FlashcardStyle = .none
    @AppStorage("flashcardImageSize") private var flashcardImageSize: Double = 150.0
    @State private var windowSize: CGSize = .zero
    
    // For more reliable timeout handling
    @State private var hideWorkItem: DispatchWorkItem? = nil
    
    // Calculate dynamic background size based on content
    private var backgroundSize: CGSize {
        let hasImage = flashcardStyle != .none
        let hasTranslation = !translation.isEmpty

        // Padding/buffer values
        let horizontalPadding: CGFloat = 100
        let verticalPadding: CGFloat = 60 // for top/bottom
        let wordTextHeight: CGFloat = 60
        let translationTextHeight: CGFloat = hasTranslation ? 40 : 0

        if hasImage {
            let width = flashcardImageSize + 2 * horizontalPadding
            let height = flashcardImageSize + verticalPadding + wordTextHeight + translationTextHeight
            // Ensure minimums for small images
            return CGSize(
                width: max(width, 400),
                height: max(height, 250)
            )
        } else {
            // No image, just use minimums
            return CGSize(width: 400, height: hasTranslation ? 250 : 200)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Show typing game view for typing game mode
            if eventHandler.isLocked && eventHandler.selectedLockEffect == .typingGame {
                TypingGameView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            else if showWord && !word.isEmpty && showFlashcards {
                let bgSize = backgroundSize
                let maxWidth = min(geometry.size.width * 0.9, bgSize.width)
                let maxHeight = min(geometry.size.height * 0.9, bgSize.height)
                
                ZStack {
                    // White background
                    Rectangle()
                        .fill(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .frame(width: maxWidth, height: maxHeight)
                    
                    VStack(spacing: 20) {
                        // Flashcard image if available
                        if flashcardStyle != .none {
                            // First check for custom image (for any word including baby's name)
                            if let customImage = loadCustomImage(for: word) {
                                Image(nsImage: customImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: min(flashcardImageSize, maxHeight - 150))
                            }
                            // Fallback to baby image if it's the baby's name (backward compatibility)
                            else if word.lowercased() == RandomWordList.shared.babyName.lowercased(),
                                    let babyImage = loadBabyImage() {
                                Image(nsImage: babyImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: min(flashcardImageSize, maxHeight - 150))
                            }
                            // Finally try generated flashcard images
                            else if let image = RandomWord(english: word, translation: translation)
                                .flashcardImage(style: flashcardStyle) {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: min(flashcardImageSize, maxHeight - 150))
                            }
                        }

                        // Main word
                        Text(word.uppercased())
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        
                        // Translation if available
                        if !translation.isEmpty {
                            Text(translation.uppercased())
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.gray)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(20)
                    .frame(width: maxWidth, height: maxHeight)
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .transition(.opacity)
            }
        }
        .fullscreenTransparentWindow()
        .onAppear {
            // Add observer for screen parameter changes
            NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { _ in
                updateWindowSize()
            }
            updateWindowSize()
        }
        .onChange(of: windowSize) { _, newSize in
            updateWindowSize()
        }
        .onReceive(eventHandler.$lastKeyString) { newValue in
            if eventHandler.isLocked && (eventHandler.selectedLockEffect == .speakAKeyWord || eventHandler.selectedLockEffect == .speakRandomWord) && !newValue.isEmpty {
                // Cancel any existing hide timers
                hideWorkItem?.cancel()
                
                if eventHandler.selectedLockEffect == .speakAKeyWord {
                    // Get the current word - lastKeyString already contains the spoken word from EventEffectHandler
                    self.word = newValue
                    
                    // Get translation if available
                    if eventHandler.selectedTranslationLanguage != .none {
                        self.translation = eventHandler.eventEffectHandler.getTranslation(
                            word: self.word,
                            language: eventHandler.selectedTranslationLanguage
                        ) ?? ""
                    } else {
                        self.translation = ""
                    }
                } else if eventHandler.selectedLockEffect == .speakRandomWord {
                    // Show words for speakRandomWord mode
                    self.word = newValue
                    
                    // For speakRandomWord, get the translation from RandomWordList
                    if let randomWordObj = RandomWordList.shared.findWord(english: newValue) {
                        self.translation = randomWordObj.translation
                    } else if eventHandler.selectedTranslationLanguage != .none {
                        self.translation = eventHandler.eventEffectHandler.getTranslation(
                            word: self.word,
                            language: eventHandler.selectedTranslationLanguage
                        ) ?? ""
                    } else {
                        self.translation = ""
                    }
                }
                
                // Show the word with animation
                withAnimation(.easeIn(duration: 0.3)) {
                    showWord = true
                }
                
                // Hide the word after the display duration
                let workItem = DispatchWorkItem {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showWord = false
                    }
                }
                hideWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + wordDisplayDuration, execute: workItem)
            }
        }
        .onReceive(Just(wordDisplayDuration)) { newDuration in
            // If a word is currently shown, update the timer with the new duration
            if showWord && hideWorkItem != nil {
                hideWorkItem?.cancel()
                
                let newHideWorkItem = DispatchWorkItem {
                    withAnimation {
                        self.showWord = false
                    }
                }
                
                self.hideWorkItem = newHideWorkItem
                
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + newDuration,
                    execute: newHideWorkItem
                )
            }
        }
        .onDisappear {
            // Clean up when view disappears
            hideWorkItem?.cancel()
            hideWorkItem = nil
        }
    }
    
    private func updateWindowSize() {
        guard let mainScreen = NSScreen.main else { return }
        let newSize = mainScreen.frame.size

        // Only update if size actually changed
        if newSize != windowSize {
            windowSize = newSize

            // Update window frame
            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == WordDisplayWindowID }) {
                    let frame = NSRect(x: 0, y: 0, width: mainScreen.frame.width, height: mainScreen.frame.height)
                    window.setFrame(frame, display: true)
                }
            }
        }
    }

    private func loadBabyImage() -> NSImage? {
        guard let babyImageURL = RandomWordList.shared.getBabyImageURL() else {
            return nil
        }

        // Start accessing security-scoped resource
        let didStartAccessing = babyImageURL.startAccessingSecurityScopedResource()

        // Load the image
        let image = NSImage(contentsOf: babyImageURL)

        // Stop accessing if we started
        if didStartAccessing {
            babyImageURL.stopAccessingSecurityScopedResource()
        }

        return image
    }

    private func loadCustomImage(for word: String) -> NSImage? {
        guard let imageURL = RandomWordList.shared.getCustomImageURL(for: word) else {
            return nil
        }

        // Start accessing security-scoped resource
        let didStartAccessing = imageURL.startAccessingSecurityScopedResource()

        // Load the image
        let image = NSImage(contentsOf: imageURL)

        // Stop accessing if we started
        if didStartAccessing {
            imageURL.stopAccessingSecurityScopedResource()
        }

        return image
    }
} 