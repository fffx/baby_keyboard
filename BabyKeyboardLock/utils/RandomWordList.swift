import Foundation
import Combine

struct RandomWord: Codable, Hashable, Identifiable {
    var id = UUID()
    let english: String
    let translation: String
}

struct RandomWordSet: Codable, Hashable, Identifiable {
    var id = UUID()
    let name: String
    let words: [RandomWord]
}

class RandomWordList: ObservableObject {
    static let shared = RandomWordList()

    private let userDefaultsKey = "randomWordSets"
    private let selectedSetIndexKey = "selectedRandomWordSetIndex"
    private let babyNameKey = "babyName"

    @Published var wordSets: [RandomWordSet] = []
    @Published var selectedWordSetIndex: Int = 0
    private(set) var babyName: String = ""

    var words: [RandomWord] {
        guard !wordSets.isEmpty, selectedWordSetIndex < wordSets.count else { return [] }
        return wordSets[selectedWordSetIndex].words
    }

    var currentWordSetName: String {
        guard !wordSets.isEmpty, selectedWordSetIndex < wordSets.count else { return "" }
        return wordSets[selectedWordSetIndex].name
    }

    // todo: rework the random picker and translation system - unify with other components (word list, flashcards, etc)
    // at least - use common translation system and flashcard images
    // todo: add baby name translation field as well
    init() {
        loadWordSets()
        loadBabyName()
        loadSelectedSetIndex()
        if wordSets.isEmpty {
            // Create default word sets
            wordSets = createDefaultWordSets()
            saveWordSets()
        }
    }

    private func createDefaultWordSets() -> [RandomWordSet] {
        let basicSet = RandomWordSet(name: "Basic Words", words: [
            RandomWord(english: "mama", translation: "мама"),
            RandomWord(english: "papa", translation: "папа"),
            RandomWord(english: "arm", translation: "рука"),
            RandomWord(english: "leg", translation: "нога"),
            RandomWord(english: "nose", translation: "нос"),
            RandomWord(english: "eye", translation: "глаз"),
            RandomWord(english: "family", translation: "семья"),
            RandomWord(english: "dog", translation: "собака"),
            RandomWord(english: "cat", translation: "кошка"),
        ])

        let animalsSet = RandomWordSet(name: "Animals", words: [
            RandomWord(english: "cat", translation: "кошка"),
            RandomWord(english: "dog", translation: "собака"),
            RandomWord(english: "bird", translation: "птица"),
            RandomWord(english: "fish", translation: "рыба"),
            RandomWord(english: "cow", translation: "корова"),
            RandomWord(english: "horse", translation: "лошадь"),
            RandomWord(english: "sheep", translation: "овца"),
            RandomWord(english: "pig", translation: "свинья"),
            RandomWord(english: "duck", translation: "утка"),
            RandomWord(english: "chicken", translation: "курица"),
            RandomWord(english: "rabbit", translation: "кролик"),
            RandomWord(english: "bear", translation: "медведь"),
            RandomWord(english: "lion", translation: "лев"),
            RandomWord(english: "elephant", translation: "слон"),
            RandomWord(english: "giraffe", translation: "жираф"),
            RandomWord(english: "monkey", translation: "обезьяна"),
            RandomWord(english: "tiger", translation: "тигр"),
            RandomWord(english: "zebra", translation: "зебра"),
            RandomWord(english: "frog", translation: "лягушка"),
            RandomWord(english: "butterfly", translation: "бабочка"),
        ])

        let bodyPartsSet = RandomWordSet(name: "Body Parts", words: [
            RandomWord(english: "head", translation: "голова"),
            RandomWord(english: "eye", translation: "глаз"),
            RandomWord(english: "nose", translation: "нос"),
            RandomWord(english: "mouth", translation: "рот"),
            RandomWord(english: "ear", translation: "ухо"),
            RandomWord(english: "hair", translation: "волосы"),
            RandomWord(english: "hand", translation: "рука"),
            RandomWord(english: "finger", translation: "палец"),
            RandomWord(english: "arm", translation: "рука"),
            RandomWord(english: "leg", translation: "нога"),
            RandomWord(english: "foot", translation: "ступня"),
            RandomWord(english: "toe", translation: "палец ноги"),
            RandomWord(english: "belly", translation: "живот"),
            RandomWord(english: "back", translation: "спина"),
            RandomWord(english: "knee", translation: "колено"),
        ])

        let foodSet = RandomWordSet(name: "Food & Drinks", words: [
            RandomWord(english: "milk", translation: "молоко"),
            RandomWord(english: "water", translation: "вода"),
            RandomWord(english: "juice", translation: "сок"),
            RandomWord(english: "apple", translation: "яблоко"),
            RandomWord(english: "banana", translation: "банан"),
            RandomWord(english: "orange", translation: "апельсин"),
            RandomWord(english: "bread", translation: "хлеб"),
            RandomWord(english: "cheese", translation: "сыр"),
            RandomWord(english: "egg", translation: "яйцо"),
            RandomWord(english: "cookie", translation: "печенье"),
            RandomWord(english: "cake", translation: "торт"),
            RandomWord(english: "ice cream", translation: "мороженое"),
            RandomWord(english: "pizza", translation: "пицца"),
            RandomWord(english: "pasta", translation: "паста"),
            RandomWord(english: "rice", translation: "рис"),
            RandomWord(english: "carrot", translation: "морковь"),
            RandomWord(english: "potato", translation: "картошка"),
        ])

        let colorsSet = RandomWordSet(name: "Colors", words: [
            RandomWord(english: "red", translation: "красный"),
            RandomWord(english: "blue", translation: "синий"),
            RandomWord(english: "green", translation: "зелёный"),
            RandomWord(english: "yellow", translation: "жёлтый"),
            RandomWord(english: "orange", translation: "оранжевый"),
            RandomWord(english: "purple", translation: "фиолетовый"),
            RandomWord(english: "pink", translation: "розовый"),
            RandomWord(english: "brown", translation: "коричневый"),
            RandomWord(english: "black", translation: "чёрный"),
            RandomWord(english: "white", translation: "белый"),
            RandomWord(english: "gray", translation: "серый"),
        ])

        let toysSet = RandomWordSet(name: "Toys & Play", words: [
            RandomWord(english: "ball", translation: "мяч"),
            RandomWord(english: "doll", translation: "кукла"),
            RandomWord(english: "bear", translation: "мишка"),
            RandomWord(english: "car", translation: "машинка"),
            RandomWord(english: "train", translation: "поезд"),
            RandomWord(english: "plane", translation: "самолёт"),
            RandomWord(english: "boat", translation: "лодка"),
            RandomWord(english: "bike", translation: "велосипед"),
            RandomWord(english: "block", translation: "кубик"),
            RandomWord(english: "puzzle", translation: "пазл"),
            RandomWord(english: "book", translation: "книга"),
            RandomWord(english: "crayon", translation: "карандаш"),
            RandomWord(english: "swing", translation: "качели"),
            RandomWord(english: "slide", translation: "горка"),
        ])

        let natureSet = RandomWordSet(name: "Nature", words: [
            RandomWord(english: "sun", translation: "солнце"),
            RandomWord(english: "moon", translation: "луна"),
            RandomWord(english: "star", translation: "звезда"),
            RandomWord(english: "cloud", translation: "облако"),
            RandomWord(english: "rain", translation: "дождь"),
            RandomWord(english: "snow", translation: "снег"),
            RandomWord(english: "wind", translation: "ветер"),
            RandomWord(english: "tree", translation: "дерево"),
            RandomWord(english: "flower", translation: "цветок"),
            RandomWord(english: "grass", translation: "трава"),
            RandomWord(english: "leaf", translation: "лист"),
            RandomWord(english: "mountain", translation: "гора"),
            RandomWord(english: "river", translation: "река"),
            RandomWord(english: "sea", translation: "море"),
        ])

        let actionsSet = RandomWordSet(name: "Actions", words: [
            RandomWord(english: "eat", translation: "есть"),
            RandomWord(english: "drink", translation: "пить"),
            RandomWord(english: "sleep", translation: "спать"),
            RandomWord(english: "walk", translation: "ходить"),
            RandomWord(english: "run", translation: "бегать"),
            RandomWord(english: "jump", translation: "прыгать"),
            RandomWord(english: "play", translation: "играть"),
            RandomWord(english: "dance", translation: "танцевать"),
            RandomWord(english: "sing", translation: "петь"),
            RandomWord(english: "read", translation: "читать"),
            RandomWord(english: "draw", translation: "рисовать"),
            RandomWord(english: "sit", translation: "сидеть"),
            RandomWord(english: "stand", translation: "стоять"),
            RandomWord(english: "clap", translation: "хлопать"),
            RandomWord(english: "wave", translation: "махать"),
        ])

        return [basicSet, animalsSet, bodyPartsSet, foodSet, colorsSet, toysSet, natureSet, actionsSet]
    }
    
    func getRandomWord() -> RandomWord? {
        // If baby name is set, include it in the random selection with 12% probability
        if !babyName.isEmpty && Int.random(in: 1...8) == 1 {
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
    
    func selectWordSet(at index: Int) {
        guard index >= 0 && index < wordSets.count else { return }
        selectedWordSetIndex = index
        saveSelectedSetIndex()
        objectWillChange.send()
        NotificationCenter.default.post(name: .init("RandomWordSetChanged"), object: nil)
    }

    func updateCurrentWordSet(_ newWords: [RandomWord]) {
        guard !wordSets.isEmpty, selectedWordSetIndex < wordSets.count else { return }
        let currentSetName = wordSets[selectedWordSetIndex].name
        wordSets[selectedWordSetIndex] = RandomWordSet(name: currentSetName, words: newWords)
        saveWordSets()
        objectWillChange.send()
        NotificationCenter.default.post(name: .init("RandomWordsUpdated"), object: nil)
    }

    func addWordSet(name: String, words: [RandomWord]) {
        let newSet = RandomWordSet(name: name, words: words)
        wordSets.append(newSet)
        saveWordSets()
        objectWillChange.send()
    }

    func deleteWordSet(at index: Int) {
        guard index >= 0 && index < wordSets.count else { return }
        wordSets.remove(at: index)
        if selectedWordSetIndex >= wordSets.count {
            selectedWordSetIndex = max(0, wordSets.count - 1)
            saveSelectedSetIndex()
        }
        saveWordSets()
        objectWillChange.send()
    }

    func renameWordSet(at index: Int, to newName: String) {
        guard index >= 0 && index < wordSets.count else { return }
        let currentWords = wordSets[index].words
        wordSets[index] = RandomWordSet(name: newName, words: currentWords)
        saveWordSets()
        objectWillChange.send()
    }

    func setBabyName(_ name: String) {
        babyName = name
        saveBabyName()
        NotificationCenter.default.post(name: .init("BabyNameUpdated"), object: nil)
    }

    private func saveWordSets() {
        if let encoded = try? JSONEncoder().encode(wordSets) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadWordSets() {
        // Try to load new format first
        if let savedSets = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedSets = try? JSONDecoder().decode([RandomWordSet].self, from: savedSets) {
            wordSets = decodedSets
            return
        }

        // Try to migrate from old format
        if let savedWords = UserDefaults.standard.data(forKey: "randomWords"),
           let decodedWords = try? JSONDecoder().decode([RandomWord].self, from: savedWords) {
            // Migrate old words to new format as "Basic Words" set
            wordSets = [RandomWordSet(name: "Basic Words (Migrated)", words: decodedWords)]
            saveWordSets()
        }
    }

    private func saveSelectedSetIndex() {
        UserDefaults.standard.set(selectedWordSetIndex, forKey: selectedSetIndexKey)
    }

    private func loadSelectedSetIndex() {
        selectedWordSetIndex = UserDefaults.standard.integer(forKey: selectedSetIndexKey)
    }

    private func saveBabyName() {
        UserDefaults.standard.set(babyName, forKey: babyNameKey)
    }

    private func loadBabyName() {
        babyName = UserDefaults.standard.string(forKey: babyNameKey) ?? ""
    }
} 