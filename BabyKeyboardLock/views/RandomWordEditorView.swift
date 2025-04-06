import SwiftUI

struct RandomWordEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var words: [RandomWord] = []
    @State private var newEnglishWord: String = ""
    @State private var newTranslation: String = ""
    
    private let randomWordList = RandomWordList.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Random Words")
                .font(.headline)
            
            Text("Edit the words used in 'Speak Random Word' mode")
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
                    randomWordList.updateWords(words)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(words.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 400)
        .onAppear {
            words = randomWordList.words
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
} 