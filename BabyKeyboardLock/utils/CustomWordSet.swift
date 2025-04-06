import Foundation
import Combine

struct CustomWordPair: Codable, Hashable, Identifiable {
    var id = UUID()
    let english: String
    let translation: String
}

struct CustomWordSet: Codable, Hashable, Identifiable {
    var id = UUID()
    let name: String
    let words: [CustomWordPair]
}

class CustomWordSetsManager: ObservableObject {
    static let shared = CustomWordSetsManager()
    
    @Published var wordSets: [CustomWordSet] = []
    @Published var selectedWordSetIndex: Int = 0
    
    private let userDefaultsKey = "customWordSets"
    
    init() {
        loadWordSets()
        // Add default "Main Words" set if no sets exist
        if wordSets.isEmpty {
            let mainWords = [
                CustomWordPair(english: "mama", translation: "мама"),
                CustomWordPair(english: "papa", translation: "папа"),
                CustomWordPair(english: "arm", translation: "рука"),
                CustomWordPair(english: "leg", translation: "нога"),
                CustomWordPair(english: "nose", translation: "нос"),
                CustomWordPair(english: "eye", translation: "глаз"),
                
                CustomWordPair(english: "apple", translation: "яблоко"),
                CustomWordPair(english: "ball", translation: "мяч"),
                CustomWordPair(english: "cat", translation: "кот"),
                CustomWordPair(english: "dog", translation: "собака"),
                CustomWordPair(english: "elephant", translation: "слон"),
                CustomWordPair(english: "fish", translation: "рыба"),
                CustomWordPair(english: "goat", translation: "коза"),
                CustomWordPair(english: "house", translation: "дом"),
                CustomWordPair(english: "ice", translation: "лёд"),
                CustomWordPair(english: "jump", translation: "прыгать"),
                CustomWordPair(english: "kite", translation: "воздушный змей"),
                CustomWordPair(english: "lion", translation: "лев"),
                CustomWordPair(english: "moon", translation: "луна"),
                CustomWordPair(english: "night", translation: "ночь"),
                CustomWordPair(english: "orange", translation: "апельсин"),
                CustomWordPair(english: "pen", translation: "ручка"),
                CustomWordPair(english: "queen", translation: "королева"),
                CustomWordPair(english: "rabbit", translation: "кролик"),
                CustomWordPair(english: "sun", translation: "солнце"),
                CustomWordPair(english: "tree", translation: "дерево"),
                CustomWordPair(english: "umbrella", translation: "зонт"),
                CustomWordPair(english: "vase", translation: "ваза"),
                CustomWordPair(english: "water", translation: "вода"),
                CustomWordPair(english: "xylophone", translation: "ксилофон"),
                CustomWordPair(english: "yellow", translation: "жёлтый"),
                CustomWordPair(english: "zebra", translation: "зебра")
            ]
            wordSets = [CustomWordSet(name: "Main Words", words: mainWords)]
            saveWordSets()
        }
    }
    
    var currentWordSet: CustomWordSet? {
        guard !wordSets.isEmpty else {
            return nil
        }
        return wordSets[0] // Always use the first word set as "Main Words"
    }
    
    func getWordMap() -> [String: [String]] {
        guard let currentSet = currentWordSet else {
            return [:]
        }
        
        var wordMap: [String: [String]] = [:]
        
        for word in currentSet.words {
            let firstLetter = String(word.english.prefix(1).lowercased())
            if wordMap[firstLetter] == nil {
                wordMap[firstLetter] = []
            }
            wordMap[firstLetter]?.append(word.english)
        }
        
        return wordMap
    }
    
    func getTranslation(for word: String) -> String? {
        guard let currentSet = currentWordSet else {
            return nil
        }
        
        return currentSet.words.first(where: { $0.english.lowercased() == word.lowercased() })?.translation
    }
    
    func updateMainWords(words: [CustomWordPair]) {
        if wordSets.isEmpty {
            wordSets = [CustomWordSet(name: "Main Words", words: words)]
        } else {
            wordSets[0] = CustomWordSet(name: "Main Words", words: words)
        }
        saveWordSets()
        objectWillChange.send()
        NotificationCenter.default.post(name: .init("MainWordsUpdated"), object: nil)
    }
    
    private func saveWordSets() {
        if let encoded = try? JSONEncoder().encode(wordSets) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadWordSets() {
        if let savedSets = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedSets = try? JSONDecoder().decode([CustomWordSet].self, from: savedSets) {
            wordSets = decodedSets
        }
    }
} 