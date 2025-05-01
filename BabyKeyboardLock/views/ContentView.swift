//
//  ContentView.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
import AppKit
import AVFoundation

// Add custom preference key for height
struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HoverableMenuStyle: MenuStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.gray.opacity(0.2) : Color.clear)
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}

struct ContentView: View {
    @State private var animationWindow: NSWindow?
    @ObservedObject var eventHandler: EventHandler = EventHandler.shared
    @State private var selectedCategory: EffectCategory = .none
    @AppStorage("showFlashcards") private var showFlashcards: Bool = false
    @AppStorage("flashcardStyle") private var flashcardStyle: FlashcardStyle = .none

    @AppStorage("lockKeyboardOnLaunch") private var lockKeyboardOnLaunch: Bool = false
    @AppStorage("launchOnStartup") private var launchOnStartup: Bool = false {
        didSet {
            LaunchAtStartup.shared.setEnabled(launchOnStartup)
        }
    }
    @AppStorage("selectedLockEffect") var selectedLockEffect: LockEffect = .none
    @AppStorage("selectedTranslationLanguage") var selectedTranslationLanguage: TranslationLanguage = .none
    @AppStorage("selectedWordSetType") var savedWordSetType: String = WordSetType.randomShortWords.rawValue
    @AppStorage("wordDisplayDuration") var wordDisplayDuration: Double = DEFAULT_WORD_DISPLAY_DURATION
    @AppStorage("usePersonalVoice") var usePersonalVoice: Bool = false
    @AppStorage("throttleInterval") private var savedThrottleInterval: Double = 1.0
    @AppStorage("confettiFadeTime") private var savedConfettiFadeTime: Double = 5.0
    
    @State private var showWordSetEditor = false
    @State private var showRandomWordEditor = false
    @StateObject private var customWordSetsManager = CustomWordSetsManager.shared
    
    @State var hoveringMoreButton: Bool = false
    @State private var babyName: String = ""
    
    // Calculate preferred content size based on effect type
    private var preferredHeight: CGFloat {
        var height: CGFloat = 300 // Base height for lock toggle and effect picker
        
        if !eventHandler.accessibilityPermissionGranted {
            height += 120 // Extra space for permission message
        }
        
        // Add space for voice options
        if eventHandler.selectedLockEffect == .speakTheKey || 
           eventHandler.selectedLockEffect == .speakAKeyWord || 
           eventHandler.selectedLockEffect == .speakRandomWord {
            height += 60
        }
        
        // Add space for word-related options
        if eventHandler.selectedLockEffect == .speakAKeyWord {
            height += 300 // Translation picker, baby name, word set selection, edit buttons
        }
        
        // Add space for random word options
        if eventHandler.selectedLockEffect == .speakRandomWord {
            height += 180 // Translation picker, edit button
        }
        
        debugPrint("Calculated preferred height: \(height) for effect: \(eventHandler.selectedLockEffect)")
        return height
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Toggle(isOn: $eventHandler.isLocked)
            {
                Label(
                    "Lock Keyboard",
                    image: eventHandler.isLocked ? "keyboard.locked" : "keyboard.unlocked"
                )
                .font(.title)
                .foregroundColor(eventHandler.accessibilityPermissionGranted ? .primary : .gray)
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))
            .scaledToFill()
            .disabled(!eventHandler.accessibilityPermissionGranted)
            .padding(.bottom, eventHandler.accessibilityPermissionGranted ? 20 : 5)
            .onChange(of: eventHandler.isLocked) { oldVal, newVal in
                playLockSound(isLocked: newVal)
            
                if eventHandler.isLocked {
                    playLockSound(isLocked: true)
                }
            }
            
            Group {
                if !eventHandler.accessibilityPermissionGranted {
                    Text("accessibility_permission_grant_hint \(Bundle.applicationName)")
                        .opacity(eventHandler.accessibilityPermissionGranted ? 0 : 1)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Category selector
                Picker("Category", selection: $selectedCategory) {
                    ForEach(EffectCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 10)
                
                // Effect selector based on category
                if selectedCategory != .none {
                    Picker("Effect", selection: $eventHandler.selectedLockEffect) {
                        ForEach(LockEffect.allCases.filter { $0.category == selectedCategory }) { effect in
                            Text(effect.localizedString).tag(effect)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Visual effects settings
                if selectedCategory == .visual {
                    if eventHandler.selectedLockEffect == .confettiCannon {
                        Group {
                            Text("Delay between confetti (seconds)")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            
                            HStack {
                                Slider(value: $eventHandler.throttleInterval, in: 0.1...2.0, step: 0.1)
                                    .onChange(of: eventHandler.throttleInterval) { _, newValue in
                                        savedThrottleInterval = newValue
                                    }
                                Text(String(format: "%.1f", eventHandler.throttleInterval))
                                    .frame(width: 35)
                            }
                            
                            Text("Confetti fade time (seconds)")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .padding(.top, 8)
                            
                            HStack {
                                Slider(value: $eventHandler.confettiFadeTime, in: 1.0...10.0, step: 0.5)
                                    .onChange(of: eventHandler.confettiFadeTime) { _, newValue in
                                        savedConfettiFadeTime = newValue
                                    }
                                Text(String(format: "%.1f", eventHandler.confettiFadeTime))
                                    .frame(width: 35)
                            }
                        }
                    }
                }
                
                // Words mode settings
                if selectedCategory == .words {
                    Toggle(isOn: $showFlashcards) {
                        Text("Show Flashcards")
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    
                    if showFlashcards {
                        Text("Flashcard Style")
                            .foregroundColor(.secondary)
                            .font(.subheadline)

                        FlashcardStylePicker(selectedStyle: $flashcardStyle)
                    }

                    Toggle(isOn: $eventHandler.usePersonalVoice) {
                        HStack {
                            Text("Use Personal Voice")
                            
                            Button(action: {
                                let alert = NSAlert()
                                alert.messageText = "About Personal Voice"
                                alert.informativeText = "Personal Voice uses your own voice created in System Settings > Accessibility > Personal Voice. You need to create a Personal Voice before using this feature."
                                alert.alertStyle = .informational
                                alert.addButton(withTitle: "OK")
                                alert.runModal()
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .onChange(of: eventHandler.usePersonalVoice) { oldVal, newVal in
                        usePersonalVoice = newVal
                    }
                    
                    // Translation picker
                    Picker("Translation", selection: $eventHandler.selectedTranslationLanguage) {
                        ForEach(TranslationLanguage.allCases) { language in
                            Text(language.localizedString)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: eventHandler.selectedTranslationLanguage) { oldVal, newVal in
                        selectedTranslationLanguage = newVal
                    }
                    
                    // Baby's name input field
                    HStack {
                        Text("Baby's Name")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        TextField("Enter name", text: $babyName, onCommit: {
                            // Do nothing, prevents form submission behavior
                        })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                            .onChange(of: babyName) { oldValue, newValue in
                                RandomWordList.shared.setBabyName(newValue)
                            }
                    }
                    
                    // Word display duration settings
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Word Display Duration: \(String(format: "%.1f", wordDisplayDuration))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("1s")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $wordDisplayDuration, in: 1...10, step: 0.5)
                            
                            Text("10s")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 5)
                    
                    // Random words editor button
                    if eventHandler.selectedLockEffect == .speakRandomWord {
                        HStack {
                            Text("Random words")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Button(action: {
                                showRandomWordEditor = true
                            }) {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Text("Contains \(RandomWordList.shared.words.count) words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $lockKeyboardOnLaunch) {
                    Text("Lock keyboard on launch")
                }
                .toggleStyle(CheckboxToggleStyle())
                
                Toggle(isOn: $launchOnStartup) {
                    Text("Launch on startup")
                }
                .toggleStyle(CheckboxToggleStyle())
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keyboard shortcut: Ctrl + Option + U")
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.secondary)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    HStack {
                        Button("About") {
                            AboutView().openInWindow(id: "About", sender: self, focus: true)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button("Quit \(Bundle.applicationName)") {
                            NSApp.terminate(nil)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 4)
                }
            }
            // Get the actual size of this content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ContentHeightKey.self, value: geo.size.height)
                        .onPreferenceChange(ContentHeightKey.self) { height in
                            debugPrint("Content height changed to: \(height)")
                            DispatchQueue.main.async {
                                updateWindowForHeight(height + 160) // Add padding and space for top elements
                            }
                        }
                }
            )
        }
        .padding(20)
        .frame(width: 600)
        .onAppear {
            debugPrint("ContentView appeared with height: \(preferredHeight)")
            updateWindowForHeight(preferredHeight)
            
            // Update initial values
            if let type = WordSetType(rawValue: savedWordSetType) {
                eventHandler.selectedWordSetType = type
            }
            babyName = RandomWordList.shared.babyName
            eventHandler.usePersonalVoice = usePersonalVoice
            launchOnStartup = LaunchAtStartup.shared.isEnabled()
            
            // Set initial category based on current effect
            selectedCategory = eventHandler.selectedLockEffect.category
            
            // Set speak random word as default for word mode
            if selectedCategory == .words && eventHandler.selectedLockEffect == .speakAKeyWord {
                eventHandler.selectedLockEffect = .speakRandomWord
            }
        }
        .onChange(of: eventHandler.isLocked) { oldVal, newVal in
            playLockSound(isLocked: newVal)
        }
        .onReceive(eventHandler.$isLocked) { newVal in
            playLockSound(isLocked: newVal)
        }
        .onChange(of: eventHandler.selectedLockEffect) { oldVal, newVal in
            selectedLockEffect = newVal
            // Force height recalculation immediately since preference might not trigger
            DispatchQueue.main.async {
                updateWindowForHeight(preferredHeight)
            }
        }
        .onChange(of: eventHandler.accessibilityPermissionGranted) { _, _ in
            // Force height recalculation
            DispatchQueue.main.async {
                updateWindowForHeight(preferredHeight)
            }
        }
        .onChange(of: selectedCategory) { oldValue, newValue in
            // When changing category, select appropriate default effect
            if newValue == .none {
                eventHandler.selectedLockEffect = .none
            } else if newValue == .visual {
                eventHandler.selectedLockEffect = .confettiCannon
            } else if newValue == .words {
                eventHandler.selectedLockEffect = .speakRandomWord
            }
        }
        .sheet(isPresented: $showWordSetEditor) {
            WordSetEditorView()
        }
        .sheet(isPresented: $showRandomWordEditor) {
            RandomWordEditorView()
        }
    }
    
    private func updateWindowForHeight(_ height: CGFloat) {
        debugPrint("Updating window to height: \(height)")
        guard height > 0 else { return }
        
        if let window = NSApp.windows.first(where: { $0.title == Bundle.applicationName || $0.title.isEmpty }) {
            let contentSize = NSSize(width: 380, height: height)
            let frameSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize)).size
            
            // Preserve the window's x and y position
            var newFrame = window.frame
            newFrame.size = frameSize
            
            // Force immediate resize without animation for more reliable results
            window.setFrame(newFrame, display: true)
            
            // Also update contentSize directly
            window.contentView?.setFrameSize(contentSize)
            
            // Log after resize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                debugPrint("Window size after direct resize: \(window.frame.size.height)")
                
                // If size doesn't match, try again with animation
                if abs(window.frame.size.height - frameSize.height) > 5 {
                    debugPrint("Size mismatch, trying again with animation")
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.2
                        window.animator().setFrame(newFrame, display: true)
                    }
                }
            }
        } else {
            debugPrint("Could not find window to resize")
        }
    }
    
    private func playLockSound(isLocked: Bool) {
        if isLocked {
            NSSound(named: "light-switch-on")?.play()
        } else {
            guard let nsSound = NSSound(named: "light-switch-off") else { return }
            
            nsSound.play()
        }
    }
    
    private func showOrCloseAnimationWindow(isLocked: Bool) {
        if (!isLocked) {
            NSApp.windows.forEach { window in
                if window.identifier?.rawValue == AnimationWindowID || window.identifier?.rawValue == WordDisplayWindowID {
                    window.close()
                }
            }
            return
        }
           
        // Check if animation window exists
        let existingAnimationWindow = NSApp.windows.first { $0.identifier?.rawValue == AnimationWindowID }
        if existingAnimationWindow != nil {
            existingAnimationWindow?.orderFront(self)
        } else {
            // Create the animation window
            animationWindow = AnimationView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    // Make the window transparent
                    guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == AnimationWindowID }) else { return }
                    window.isOpaque = false
                    window.level = .floating
                    window.titlebarAppearsTransparent = true
                }
                .openInWindow(id: AnimationWindowID, sender: self)
        }
        
        // Check if word display window exists
        let existingWordDisplayWindow = NSApp.windows.first { $0.identifier?.rawValue == WordDisplayWindowID }
        if existingWordDisplayWindow != nil {
            existingWordDisplayWindow?.orderFront(self)
        } else {
            // Create the word display window
            WordDisplayView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    // Make the window transparent
                    guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == WordDisplayWindowID }) else { return }
                    window.isOpaque = false
                    window.backgroundColor = NSColor.clear
                    window.level = .floating
                    window.ignoresMouseEvents = true
                    window.titlebarAppearsTransparent = true
                }
                .openInWindow(id: WordDisplayWindowID, sender: self)
        }
    }
    
}

struct WordSetEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var customWordSetsManager = CustomWordSetsManager.shared
    @State private var words: [CustomWordPair] = []
    @State private var newEnglishWord: String = ""
    @State private var newTranslation: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Main Words")
                .font(.headline)
            
            Text("Edit the words used in 'Main Words' set")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            List {
                ForEach(words) { word in
                    HStack {
                        Text(word.english)
                        Spacer()
                        Text(word.translation)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: deleteWord)
            }
            .listStyle(PlainListStyle())
            .frame(height: 200)
            
            HStack {
                TextField("English word", text: $newEnglishWord)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Translation", text: $newTranslation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addWord) {
                    Image(systemName: "plus")
                }
                .disabled(newEnglishWord.isEmpty || newTranslation.isEmpty)
            }
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button("Save") {
                    customWordSetsManager.updateMainWords(words: words)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(words.isEmpty)
            }
        } 
        .padding()
        .frame(width: 400, height: 400)
        .onAppear {
            if let currentSet = customWordSetsManager.currentWordSet {
                words = currentSet.words
            }
        }
    }
    
    private func addWord() {
        guard !newEnglishWord.isEmpty && !newTranslation.isEmpty else { return }
        
        let newWord = CustomWordPair(english: newEnglishWord, translation: newTranslation) 
        words.append(newWord)
        
        // Clear the input fields
        newEnglishWord = ""
        newTranslation = ""
    }
    
    private func deleteWord(at offsets: IndexSet) {
        words.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView(eventHandler: EventHandler(isLocked: false))
}
