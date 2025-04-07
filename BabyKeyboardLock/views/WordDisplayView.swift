import SwiftUI
import Combine

struct WordDisplayView: View {
    @ObservedObject var eventHandler: EventHandler = EventHandler.shared
    @State private var word: String = ""
    @State private var translation: String = ""
    @State private var showWord: Bool = false
    @AppStorage("wordDisplayDuration") private var wordDisplayDuration: Double = DEFAULT_WORD_DISPLAY_DURATION
    
    // For more reliable timeout handling
    @State private var hideWorkItem: DispatchWorkItem? = nil
    
    var body: some View {
        GeometryReader { geometry in
            if showWord && !word.isEmpty {
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
                withAnimation {
                    self.showWord = true
                }
                
                // Set up a new hide timer
                let newHideWorkItem = DispatchWorkItem {
                    withAnimation {
                        self.showWord = false
                    }
                }
                
                self.hideWorkItem = newHideWorkItem
                
                // Schedule hiding after configured duration
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + wordDisplayDuration,
                    execute: newHideWorkItem
                )
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
} 