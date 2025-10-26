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

// MARK: - Window Manager Helper
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    private var cachedMainWindow: NSWindow?
    private var lastUpdateTime: Date = Date()
    private let debounceInterval: TimeInterval = 0.1
    private var pendingHeight: CGFloat?
    private var updateWorkItem: DispatchWorkItem?
    
    private init() {}
    
    func updateWindowHeight(_ height: CGFloat, force: Bool = false) {
        guard height > 0 else { return }
        
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime)
        
        // Cancel any pending update
        updateWorkItem?.cancel()
        
        // Store the pending height
        pendingHeight = height
        
        // If forced or enough time has passed, update immediately
        if force || timeSinceLastUpdate >= debounceInterval {
            performUpdate(height)
        } else {
            // Debounce the update with longer delay to prevent rapid updates
            let workItem = DispatchWorkItem { [weak self] in
                if let pendingHeight = self?.pendingHeight {
                    self?.performUpdate(pendingHeight)
                }
            }
            updateWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
        }
    }
    
    private func performUpdate(_ height: CGFloat) {
        lastUpdateTime = Date()
        pendingHeight = nil
        
        let window = getMainWindow()
        guard let window = window else {
            return // Don't log this error, it's too noisy
        }
        
        let contentSize = NSSize(width: 500, height: height)
        let frameSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize)).size
        
        // Check if resize is actually needed
        if abs(window.frame.size.height - frameSize.height) < 5 {
            return // Skip unnecessary resize with larger threshold
        }
        
        debugPrint("Updating window to height: \(height)")
        
        var newFrame = window.frame
        newFrame.size = frameSize
        
        // Use immediate resize for better performance
        window.setFrame(newFrame, display: true, animate: false)
    }
    
    private func getMainWindow() -> NSWindow? {
        // Cache the main window reference for better performance
        if let cached = cachedMainWindow, cached.isVisible {
            return cached
        }

        // Look for popover or main content window
        // Popovers have empty titles and special window classes
        let window = NSApp.windows.first(where: { window in
            // Check if it's the main app window by title
            if window.title == Bundle.applicationName {
                return true
            }
            // Check if it's a popover window (empty title, has content)
            if window.title.isEmpty && window.contentView != nil {
                // Verify it's not one of our transparent windows
                if let identifier = window.identifier?.rawValue {
                    return ![AnimationWindowID, WordDisplayWindowID, VisualEffectsWindowID].contains(identifier)
                }
                return true
            }
            return false
        })
        cachedMainWindow = window
        return window
    }
    
    func invalidateCache() {
        cachedMainWindow = nil
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
    @AppStorage("wordsThrottleInterval") private var savedWordsThrottleInterval: Double = 1.5
    @AppStorage("confettiFadeTime") private var savedConfettiFadeTime: Double = 5.0
    @AppStorage("wordTranslationDelay") private var savedWordTranslationDelay: Double = 0.8
    @AppStorage("flashcardImageSize") private var flashcardImageSize: Double = 150.0

    @State private var showWordSetEditor = false
    @State private var showRandomWordEditor = false
    @State private var showCustomWordImageEditor = false
    @StateObject private var customWordSetsManager = CustomWordSetsManager.shared
    @StateObject private var randomWordList = RandomWordList.shared
    @StateObject private var windowManager = WindowManager.shared

    @State var hoveringMoreButton: Bool = false
    @State private var babyName: String = ""
    @State private var babyNameTranslation: String = ""
    @State private var babyNameProbability: Double = 0.125
    @State private var babyImagePath: String = ""
    @State private var lastCalculatedHeight: CGFloat = 0
    
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
            height += 330 // Translation picker, baby name + translation, word set selection, edit buttons
        }

        // Add space for random word options
        if eventHandler.selectedLockEffect == .speakRandomWord {
            height += 310 // Translation picker, baby name + translation + image, baby name probability, edit button
        }

        // Add space for game mode options
        if eventHandler.selectedLockEffect == .typingGame {
            height += 200 // Reset on error toggle, word set selector, flashcard options
        }

        return height
    }
    
    private func calculateAndUpdateHeight() {
        let newHeight = preferredHeight
        // Only log and update if height actually changed
        if abs(newHeight - lastCalculatedHeight) > 5 {
            debugPrint("Calculated preferred height: \(newHeight) for effect: \(eventHandler.selectedLockEffect)")
            lastCalculatedHeight = newHeight
            windowManager.updateWindowHeight(newHeight, force: true)
        }
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This app needs Accessibility access to work.")
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            Button("Grant Accessibility Access") {
                                NSApp.activate(ignoringOtherApps: true)
                                _ = eventHandler.requestAccessibilityPermissions()
                            }

                            Button("Open System Settings…") {
                                NSApp.activate(ignoringOtherApps: true)
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }
                    }
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
                    let availableEffects = LockEffect.allCases.filter { $0.category == selectedCategory }
                    Picker("Effect", selection: $eventHandler.selectedLockEffect) {
                        ForEach(availableEffects) { effect in
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
                    
                    // Words throttle setting
                    Text("Delay between words (seconds)")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding(.top, 8)
                    
                    HStack {
                        Slider(value: $eventHandler.wordsThrottleInterval, in: 0.1...3.0, step: 0.1)
                            .onChange(of: eventHandler.wordsThrottleInterval) { _, newValue in
                                savedWordsThrottleInterval = newValue
                            }
                        Text(String(format: "%.1f", eventHandler.wordsThrottleInterval))
                            .frame(width: 35)
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
                    
                    // Baby's name input fields
                    VStack(alignment: .leading, spacing: 8) {
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

                        HStack {
                            Text("Second Language Name")
                                .foregroundColor(.secondary)
                                .font(.subheadline)

                            Spacer()

                            TextField("Enter translation", text: $babyNameTranslation, onCommit: {
                                // Do nothing, prevents form submission behavior
                            })
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 150)
                                .onChange(of: babyNameTranslation) { oldValue, newValue in
                                    RandomWordList.shared.setBabyNameTranslation(newValue)
                                }
                        }

                        HStack {
                            Text("Baby's Image")
                                .foregroundColor(.secondary)
                                .font(.subheadline)

                            Spacer()

                            if !babyImagePath.isEmpty {
                                Text(URL(fileURLWithPath: babyImagePath).lastPathComponent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .frame(maxWidth: 100)
                            }

                            Button(action: selectBabyImage) {
                                Text(babyImagePath.isEmpty ? "Select Image" : "Change")
                            }
                            .buttonStyle(.plain)

                            if !babyImagePath.isEmpty {
                                Button(action: {
                                    babyImagePath = ""
                                    RandomWordList.shared.setBabyImagePath("")
                                }) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Divider()
                            .padding(.vertical, 8)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Other Custom Images")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                Text("Add images for mama, papa, family, etc.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if !randomWordList.customWordImages.isEmpty {
                                    Text("\(randomWordList.customWordImages.count) custom image(s)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Button(action: {
                                showCustomWordImageEditor = true
                            }) {
                                Image(systemName: "photo.on.rectangle.angled")
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Baby name probability slider (only for random word mode)
                    if eventHandler.selectedLockEffect == .speakRandomWord {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Baby Name Frequency: \(String(format: "%.0f%%", babyNameProbability * 100))")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("0%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Slider(value: $babyNameProbability, in: 0...1, step: 0.01)
                                    .onChange(of: babyNameProbability) { _, newValue in
                                        RandomWordList.shared.setBabyNameProbability(newValue)
                                    }

                                Text("100%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 5)
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Word Sets")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                Text("\(randomWordList.enabledSetIndices.count) enabled (\(randomWordList.words.count) words)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if !randomWordList.enabledWordSetNames.isEmpty && randomWordList.enabledWordSetNames != "None" {
                                    Text(randomWordList.enabledWordSetNames)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            Button(action: {
                                showRandomWordEditor = true
                            }) {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Image size slider for random word mode
                        if showFlashcards && flashcardStyle != .none {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Image Size: \(Int(flashcardImageSize))px")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("50px")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Slider(value: $flashcardImageSize, in: 50...1000, step: 50)
                                    
                                    Text("1000px")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }

                // Game mode settings
                if selectedCategory == .games {
                    Toggle(isOn: Binding(
                        get: { TypingGameState.shared.resetOnError },
                        set: { TypingGameState.shared.setResetOnError($0) }
                    )) {
                        Text("Reset on error")
                    }
                    .toggleStyle(CheckboxToggleStyle())

                    // Word set selection
                    Picker("Word Set", selection: $eventHandler.selectedWordSetType) {
                        ForEach(WordSetType.allCases) { type in
                            Text(type.localizedString).tag(type)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: eventHandler.selectedWordSetType) { _, newValue in
                        savedWordSetType = newValue.rawValue
                    }

                    // Show flashcards toggle
                    Toggle(isOn: $showFlashcards) {
                        Text("Show Flashcards")
                    }
                    .toggleStyle(CheckboxToggleStyle())

                    if showFlashcards {
                        Text("Flashcard Style")
                            .foregroundColor(.secondary)
                            .font(.subheadline)

                        FlashcardStylePicker(selectedStyle: $flashcardStyle)

                        // Image size slider
                        if flashcardStyle != .none {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Image Size: \(Int(flashcardImageSize))px")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                HStack {
                                    Text("50px")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Slider(value: $flashcardImageSize, in: 50...1000, step: 50)

                                    Text("1000px")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 8)
                        }
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
            // Get the actual size of this content with better debouncing
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ContentHeightKey.self, value: geo.size.height)
                        .onPreferenceChange(ContentHeightKey.self) { height in
                            let totalHeight = height + 160 // Add padding and space for top elements
                            // Only update if height changed significantly and enough time has passed
                            if abs(totalHeight - lastCalculatedHeight) > 20 && height > 50 {
                                debugPrint("Content height changed to: \(height)")
                                lastCalculatedHeight = totalHeight
                                // Add small delay to let SwiftUI finish its layout calculations
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    windowManager.updateWindowHeight(totalHeight)
                                }
                            }
                        }
                }
            )
        }
        .padding(20)
        .frame(width: 500)
        .onAppear {
            // Set initial values first
            if let type = WordSetType(rawValue: savedWordSetType) {
                eventHandler.selectedWordSetType = type
            }
            babyName = RandomWordList.shared.babyName
            babyNameTranslation = RandomWordList.shared.babyNameTranslation
            babyNameProbability = RandomWordList.shared.babyNameProbability
            babyImagePath = RandomWordList.shared.babyImagePath
            eventHandler.usePersonalVoice = usePersonalVoice
            launchOnStartup = LaunchAtStartup.shared.isEnabled()

            // Set initial category based on current effect
            selectedCategory = eventHandler.selectedLockEffect.category

            // Set speak random word as default for word mode
            if selectedCategory == .words && eventHandler.selectedLockEffect == .speakAKeyWord {
                eventHandler.selectedLockEffect = .speakRandomWord
            }

            // Request accessibility permissions if needed
            if !eventHandler.accessibilityPermissionGranted {
                NSApp.activate(ignoringOtherApps: true)
                _ = eventHandler.requestAccessibilityPermissions()
            }

            // Delay window sizing to after UI stabilizes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let initialHeight = preferredHeight
                debugPrint("ContentView appeared with height: \(initialHeight)")
                lastCalculatedHeight = initialHeight
                windowManager.updateWindowHeight(initialHeight, force: true)
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
            calculateAndUpdateHeight()
        }
        .onChange(of: eventHandler.accessibilityPermissionGranted) { _, _ in
            // Force height recalculation
            calculateAndUpdateHeight()
        }
        .onChange(of: selectedCategory) { oldValue, newValue in
            // When changing category, only switch if current effect is incompatible
            let availableEffects = LockEffect.allCases.filter { $0.category == newValue }

            if newValue == .none {
                eventHandler.selectedLockEffect = .none
            } else if !availableEffects.contains(eventHandler.selectedLockEffect) {
                // Current effect doesn't match category, preserve user preference if possible
                if newValue == .visual {
                    eventHandler.selectedLockEffect = .confettiCannon
                } else if newValue == .words {
                    eventHandler.selectedLockEffect = .speakRandomWord
                } else if newValue == .games {
                    eventHandler.selectedLockEffect = .typingGame
                }
            }
            // If current effect is compatible with new category, keep it unchanged
        }
        .sheet(isPresented: $showWordSetEditor) {
            WordSetEditorView()
        }
        .sheet(isPresented: $showRandomWordEditor) {
            RandomWordEditorView()
        }
        .sheet(isPresented: $showCustomWordImageEditor) {
            CustomWordImageEditorView()
        }
    }
    

    
    private func selectBabyImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        panel.message = "Select an image for your baby"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                babyImagePath = url.path
                RandomWordList.shared.setBabyImageURL(url)
            }
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

struct CustomWordImageEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var randomWordList = RandomWordList.shared
    @State private var customImages: [CustomWordImage] = []
    @State private var newWord: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Word Images")
                .font(.headline)

            Text("Add custom images for specific words (e.g., 'mama', 'papa', family members)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            List {
                ForEach(customImages) { customImage in
                    HStack {
                        Text(customImage.word)
                            .font(.body)
                        Spacer()
                        Text(URL(fileURLWithPath: customImage.imagePath).lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 150)

                        Button(action: {
                            selectImageForWord(customImage.word)
                        }) {
                            Image(systemName: "photo")
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            randomWordList.removeCustomWordImage(word: customImage.word)
                            loadCustomImages()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
            .frame(height: 200)

            HStack {
                TextField("Word (e.g., mama, papa)", text: $newWord)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: {
                    if !newWord.isEmpty {
                        selectImageForWord(newWord)
                    }
                }) {
                    Image(systemName: "plus")
                }
                .disabled(newWord.isEmpty)
            }

            Divider()
                .padding(.vertical, 8)

            HStack {
                Text("Quick Add:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button("Mama") {
                    addQuickWord("mama")
                }
                .buttonStyle(.plain)

                Button("Papa") {
                    addQuickWord("papa")
                }
                .buttonStyle(.plain)

                Button("Grandma") {
                    addQuickWord("grandma")
                }
                .buttonStyle(.plain)

                Button("Grandpa") {
                    addQuickWord("grandpa")
                }
                .buttonStyle(.plain)
            }

            HStack {
                Spacer()

                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .padding()
        .frame(width: 550, height: 450)
        .onAppear {
            loadCustomImages()
        }
    }

    private func loadCustomImages() {
        customImages = randomWordList.customWordImages
    }

    private func addQuickWord(_ word: String) {
        // Check if word already exists
        if customImages.contains(where: { $0.word.lowercased() == word.lowercased() }) {
            // Just select new image
            selectImageForWord(word)
        } else {
            newWord = word
            selectImageForWord(word)
        }
    }

    private func selectImageForWord(_ word: String) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        panel.message = "Select an image for '\(word)'"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                randomWordList.setCustomWordImage(word: word, url: url)
                loadCustomImages()
                newWord = ""
            }
        }
    }
}

#Preview {
    ContentView(eventHandler: EventHandler(isLocked: false))
}
