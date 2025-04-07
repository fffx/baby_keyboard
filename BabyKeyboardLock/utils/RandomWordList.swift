import Foundation

struct RandomWord: Codable, Hashable, Identifiable {
    var id = UUID()
    let english: String
    let translation: String
}

class RandomWordList {
    static let shared = RandomWordList()
    
    private let userDefaultsKey = "randomWords"
    private let babyNameKey = "babyName"
    
    private(set) var words: [RandomWord] = []
    private(set) var babyName: String = ""
    
    init() {
        loadWords()
        loadBabyName()
        if words.isEmpty {
            // Default words list
            words = [
                RandomWord(english: "mama", translation: "мама"),
                RandomWord(english: "papa", translation: "папа"),
                RandomWord(english: "arm", translation: "рука"),
                RandomWord(english: "leg", translation: "нога"),
                RandomWord(english: "nose", translation: "нос"),
                RandomWord(english: "eye", translation: "глаз")
            ]
            saveWords()
        }
    }
    
    func getRandomWord() -> RandomWord? {
        // If baby name is set, include it in the random selection with 25% probability
        if !babyName.isEmpty && Int.random(in: 1...4) == 1 {
            return RandomWord(english: babyName, translation: babyName)
        }
        
        guard !words.isEmpty else { return nil }
        return words.randomElement()
    }
    
    func findWord(english: String) -> RandomWord? {
        if english.lowercased() == babyName.lowercased() {
            return RandomWord(english: babyName, translation: babyName)
        }
        return words.first { $0.english.lowercased() == english.lowercased() }
    }
    
    func updateWords(_ newWords: [RandomWord]) {
        words = newWords
        saveWords()
        NotificationCenter.default.post(name: .init("RandomWordsUpdated"), object: nil)
    }
    
    func setBabyName(_ name: String) {
        babyName = name
        saveBabyName()
        NotificationCenter.default.post(name: .init("BabyNameUpdated"), object: nil)
    }
    
    private func saveWords() {
        if let encoded = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadWords() {
        if let savedWords = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedWords = try? JSONDecoder().decode([RandomWord].self, from: savedWords) {
            words = decodedWords
        }
    }
    
    private func saveBabyName() {
        UserDefaults.standard.set(babyName, forKey: babyNameKey)
    }
    
    private func loadBabyName() {
        babyName = UserDefaults.standard.string(forKey: babyNameKey) ?? ""
    }
} 