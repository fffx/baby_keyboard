import SwiftUI
import Combine

struct WordDisplayView: View {
    @ObservedObject var eventHandler: EventHandler = EventHandler.shared
    @State private var word: String = ""
    @State private var translation: String = ""
    @State private var showWord: Bool = false
    @AppStorage("wordDisplayDuration") private var wordDisplayDuration: Double = DEFAULT_WORD_DISPLAY_DURATION
    @AppStorage("showFlashcards") private var showFlashcards: Bool = false
    @State private var windowSize: CGSize = .zero
    
    // For more reliable timeout handling
    @State private var hideWorkItem: DispatchWorkItem? = nil
    
    var body: some View {
        GeometryReader { geometry in
            if showWord && !word.isEmpty && showFlashcards {
                ZStack {
                    // White background
                    Rectangle()
                        .fill(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .frame(width: min(geometry.size.width * 0.8, 500), height: 200)
                    
                    VStack(spacing: 20) {
                        // Main word
                        Text(word.uppercased())
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.black)
                        
                        // Translation if available
                        if !translation.isEmpty {
                            Text(translation.uppercased())
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(width: min(geometry.size.width * 0.8, 500), height: 200)
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
} 