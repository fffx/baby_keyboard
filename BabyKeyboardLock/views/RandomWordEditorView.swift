import SwiftUI

struct RandomWordEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var randomWordList = RandomWordList.shared
    @State private var selectedSetIndex: Int? = nil
    @State private var words: [RandomWord] = []
    @State private var newEnglishWord: String = ""
    @State private var newTranslation: String = ""
    @State private var showingNewSetDialog = false
    @State private var newSetName: String = ""
    @State private var showingRenameDialog = false
    @State private var renameSetIndex: Int? = nil
    @State private var renameSetName: String = ""
    @State private var showingResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Random Word Sets")
                .font(.headline)

            HStack {
                Button(action: { showingNewSetDialog = true }) {
                    Label("New Set", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)

                Button(action: { showingResetConfirmation = true }) {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
                .foregroundColor(.orange)

                Spacer()

                Text("\(randomWordList.enabledSetIndices.count) of \(randomWordList.wordSets.count) enabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Wordset list with checkboxes
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(0..<randomWordList.wordSets.count, id: \.self) { index in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { randomWordList.isSetEnabled(at: index) },
                                set: { _ in randomWordList.toggleSet(at: index) }
                            )) {
                                EmptyView()
                            }
                            .toggleStyle(CheckboxToggleStyle())
                            .frame(width: 20)

                            Button(action: {
                                selectedSetIndex = index
                                words = randomWordList.wordSets[index].words
                            }) {
                                HStack {
                                    Text(randomWordList.wordSets[index].name)
                                        .foregroundColor(selectedSetIndex == index ? .accentColor : .primary)
                                    Spacer()
                                    Text("\(randomWordList.wordSets[index].words.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                renameSetIndex = index
                                renameSetName = randomWordList.wordSets[index].name
                                showingRenameDialog = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)

                            Button(action: { deleteSet(at: index) }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .disabled(randomWordList.wordSets.count <= 1)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(height: 200)
            .border(Color.gray.opacity(0.3))

            if let selectedIndex = selectedSetIndex {
                Divider()

                Text("Edit '\(randomWordList.wordSets[selectedIndex].name)'")
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

                    Button("Save Changes") {
                        if let index = selectedSetIndex {
                            randomWordList.updateWordSet(at: index, newWords: words)
                        }
                    }
                    .disabled(words.isEmpty)
                }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .padding()
        .frame(width: 600, height: 550)
        .alert("New Word Set", isPresented: $showingNewSetDialog) {
            TextField("Set name", text: $newSetName)
            Button("Cancel", role: .cancel) {
                newSetName = ""
            }
            Button("Create") {
                if !newSetName.isEmpty {
                    randomWordList.addWordSet(name: newSetName, words: [])
                    selectedSetIndex = randomWordList.wordSets.count - 1
                    words = []
                    newSetName = ""
                }
            }
        }
        .alert("Rename Word Set", isPresented: $showingRenameDialog) {
            TextField("Set name", text: $renameSetName)
            Button("Cancel", role: .cancel) {
                renameSetIndex = nil
                renameSetName = ""
            }
            Button("Rename") {
                if !renameSetName.isEmpty, let index = renameSetIndex {
                    randomWordList.renameWordSet(at: index, to: renameSetName)
                    renameSetIndex = nil
                }
            }
        }
        .alert("Reset to Defaults", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("This will restore all default word sets and remove any custom sets you've created. Your baby's name will be preserved. This action cannot be undone.")
        }
    }

    private func resetToDefaults() {
        randomWordList.resetToDefaults()
        selectedSetIndex = nil
        words = []
    }

    private func addWord() {
        guard !newEnglishWord.isEmpty && !newTranslation.isEmpty else { return }

        let newWord = RandomWord(english: newEnglishWord, translation: newTranslation)
        words.append(newWord)

        // Clear the input fields
        newEnglishWord = ""
        newTranslation = ""
    }

    private func deleteWord(at offsets: IndexSet) {
        words.remove(atOffsets: offsets)
    }

    private func deleteSet(at index: Int) {
        let alert = NSAlert()
        alert.messageText = "Delete Word Set"
        alert.informativeText = "Are you sure you want to delete '\(randomWordList.wordSets[index].name)'?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            randomWordList.deleteWordSet(at: index)
            if selectedSetIndex == index {
                selectedSetIndex = nil
                words = []
            } else if let selectedIndex = selectedSetIndex, selectedIndex > index {
                selectedSetIndex = selectedIndex - 1
            }
        }
    }
} 