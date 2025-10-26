//
//  TypingGameView.swift
//  BabyKeyboardLock
//
//  Created by Claude on 24.10.2025.
//
import SwiftUI

struct TypingGameView: View {
    @ObservedObject var eventHandler = EventHandler.shared
    @ObservedObject var typingGameState = TypingGameState.shared
    @AppStorage("showFlashcards") private var showFlashcards: Bool = false
    @AppStorage("flashcardStyle") private var flashcardStyle: FlashcardStyle = .none
    @AppStorage("flashcardImageSize") private var flashcardImageSize: Double = 150.0
    @State private var showCelebration: Bool = false
    @State private var celebrationOpacity: Double = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main typing display
                VStack(spacing: 40) {
                    Spacer()

                    // Target word display with typed letters highlighted
                    if !typingGameState.currentWord.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(typingGameState.currentWord.enumerated()), id: \.offset) { index, char in
                                Text(String(char))
                                    .font(.system(size: 80, weight: .bold, design: .rounded))
                                    .foregroundColor(index < typingGameState.typedSoFar.count ? .green : .gray.opacity(0.5))
                                    .scaleEffect(index == typingGameState.typedSoFar.count - 1 ? 1.3 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: typingGameState.typedSoFar.count)
                            }
                        }
                        .padding()
                    }

                    // Flashcard image if enabled
                    if showFlashcards && flashcardStyle != .none {
                        if let imagePath = getImagePath() {
                            if let nsImage = NSImage(contentsOfFile: imagePath) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: CGFloat(flashcardImageSize), height: CGFloat(flashcardImageSize))
                                    .shadow(radius: 10)
                            }
                        }
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Celebration animation overlay
                if showCelebration {
                    VStack {
                        Text("🎉")
                            .font(.system(size: 200))
                            .opacity(celebrationOpacity)
                            .scaleEffect(celebrationOpacity)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: celebrationOpacity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onChange(of: typingGameState.isWordComplete) { oldValue, newValue in
                if newValue {
                    // Trigger celebration animation
                    withAnimation {
                        showCelebration = true
                        celebrationOpacity = 1.0
                    }

                    // Fade out after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            celebrationOpacity = 0.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showCelebration = false
                        }
                    }
                }
            }
        }
    }

    private func getImagePath() -> String? {
        let word = typingGameState.currentWord.lowercased()

        // Check for custom word image first
        if let customImage = RandomWordList.shared.customWordImages.first(where: { $0.word.lowercased() == word }) {
            return customImage.imagePath
        }

        // Check for baby image if word matches baby name
        if !RandomWordList.shared.babyImagePath.isEmpty &&
           word == RandomWordList.shared.babyName.lowercased() {
            return RandomWordList.shared.babyImagePath
        }

        // Try to find image in Resources
        if let resourcePath = Bundle.main.resourcePath {
            let imagePath = "\(resourcePath)/Resources/\(word).png"
            if FileManager.default.fileExists(atPath: imagePath) {
                return imagePath
            }
        }

        return nil
    }
}

#Preview {
    TypingGameView()
        .frame(width: 800, height: 600)
}
