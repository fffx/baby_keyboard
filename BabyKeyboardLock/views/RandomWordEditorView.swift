import SwiftUI

struct RandomWordEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var randomWordList = RandomWordList.shared
    @State private var words: [RandomWord] = []
    @State private var newEnglishWord: String = ""
    @State private var newTranslation: String = ""
    @State private var showingNewSetDialog = false
    @State private var newSetName: String = ""
    @State private var showingRenameDialog = false
    @State private var renameSetName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Random Words")
                    .font(.headline)

                Spacer()

                // Word set selector
                Picker("Word Set", selection: $randomWordList.selectedWordSetIndex) {
                    ForEach(0..<randomWordList.wordSets.count, id: \.self) { index in
                        Text(randomWordList.wordSets[index].name).tag(index)
                    }
                }
                .frame(width: 200)
                .onChange(of: randomWordList.selectedWordSetIndex) { oldValue, newValue in
                    words = randomWordList.words
                }
            }

            HStack {
                Button(action: { showingNewSetDialog = true }) {
                    Label("New Set", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)

                Button(action: { showingRenameDialog = true }) {
                    Label("Rename", systemImage: "pencil")
                }
                .buttonStyle(.plain)

                Button(action: deleteCurrentSet) {
                    Label("Delete Set", systemImage: "trash")
                }
                .buttonStyle(.plain)
                .disabled(randomWordList.wordSets.count <= 1)
            }
            .font(.subheadline)

            Text("Edit the words in '\(randomWordList.currentWordSetName)'")
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
                    randomWordList.updateCurrentWordSet(words)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(words.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 450)
        .onAppear {
            words = randomWordList.words
            renameSetName = randomWordList.currentWordSetName
        }
        .alert("New Word Set", isPresented: $showingNewSetDialog) {
            TextField("Set name", text: $newSetName)
            Button("Cancel", role: .cancel) {
                newSetName = ""
            }
            Button("Create") {
                if !newSetName.isEmpty {
                    randomWordList.addWordSet(name: newSetName, words: [])
                    randomWordList.selectWordSet(at: randomWordList.wordSets.count - 1)
                    words = []
                    newSetName = ""
                }
            }
        }
        .alert("Rename Word Set", isPresented: $showingRenameDialog) {
            TextField("Set name", text: $renameSetName)
            Button("Cancel", role: .cancel) {
                renameSetName = randomWordList.currentWordSetName
            }
            Button("Rename") {
                if !renameSetName.isEmpty {
                    randomWordList.renameWordSet(at: randomWordList.selectedWordSetIndex, to: renameSetName)
                }
            }
        }
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

    private func deleteCurrentSet() {
        let alert = NSAlert()
        alert.messageText = "Delete Word Set"
        alert.informativeText = "Are you sure you want to delete '\(randomWordList.currentWordSetName)'?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            randomWordList.deleteWordSet(at: randomWordList.selectedWordSetIndex)
            words = randomWordList.words
        }
    }
} 