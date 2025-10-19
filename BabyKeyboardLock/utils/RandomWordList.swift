import Foundation
import Combine

struct RandomWord: Codable, Hashable, Identifiable {
    var id = UUID()
    let english: String
    let translation: String
}

struct CustomWordImage: Codable, Hashable, Identifiable {
    var id = UUID()
    let word: String  // The word this image is for
    let imagePath: String  // Path to the custom image
}

struct RandomWordSet: Codable, Hashable, Identifiable {
    var id = UUID()
    let name: String
    let words: [RandomWord]
}

class RandomWordList: ObservableObject {
    static let shared = RandomWordList()

    private let userDefaultsKey = "randomWordSets"
    private let enabledSetsKey = "enabledRandomWordSets"
    private let babyNameKey = "babyName"
    private let babyNameTranslationKey = "babyNameTranslation"
    private let babyNameProbabilityKey = "babyNameProbability"
    private let babyImagePathKey = "babyImagePath"
    private let babyImageBookmarkKey = "babyImageBookmark"
    private let customWordImagesKey = "customWordImages"
    private let customWordImageBookmarksKey = "customWordImageBookmarks"

    @Published var wordSets: [RandomWordSet] = []
    @Published var enabledSetIndices: Set<Int> = []
    private(set) var babyName: String = ""
    private(set) var babyNameTranslation: String = ""
    @Published var babyNameProbability: Double = 0.125 // Default 12.5% (1 in 8)
    @Published var babyImagePath: String = ""
    private var babyImageBookmark: Data?
    @Published var customWordImages: [CustomWordImage] = []
    private var customWordImageBookmarks: [String: Data] = [:] // word -> bookmark data

    var words: [RandomWord] {
        var allWords: [RandomWord] = []
        for index in enabledSetIndices.sorted() {
            guard index < wordSets.count else { continue }
            allWords.append(contentsOf: wordSets[index].words)
        }
        return allWords
    }

    var enabledWordSetNames: String {
        let names = enabledSetIndices.sorted().compactMap { (index: Int) -> String? in
            guard index < wordSets.count else { return nil }
            return wordSets[index].name
        }
        return names.isEmpty ? "None" : names.joined(separator: ", ")
    }

    func isSetEnabled(at index: Int) -> Bool {
        enabledSetIndices.contains(index)
    }

    func toggleSet(at index: Int) {
        if enabledSetIndices.contains(index) {
            enabledSetIndices.remove(index)
        } else {
            enabledSetIndices.insert(index)
        }
        saveEnabledSets()
        objectWillChange.send()
        NotificationCenter.default.post(name: .init("RandomWordSetChanged"), object: nil)
    }

    // todo: rework the random picker and translation system - unify with other components (word list, flashcards, etc)
    // at least - use common translation system and flashcard images
    init() {
        loadWordSets()
        loadBabyName()
        loadBabyNameTranslation()
        loadBabyNameProbability()
        loadBabyImagePath()
        loadCustomWordImages()
        loadEnabledSets()
        if wordSets.isEmpty {
            // Create default word sets
            wordSets = createDefaultWordSets()
            saveWordSets()
            // Enable first set by default
            if !wordSets.isEmpty {
                enabledSetIndices = [0]
                saveEnabledSets()
            }
        }
    }

    private func createDefaultWordSets() -> [RandomWordSet] {
        // Basic Set - legacy, first one
	      let basicSet = RandomWordSet(name: "Basic Words", words: [
            RandomWord(english: "mama", translation: "мама"),
            RandomWord(english: "papa", translation: "папа"),
            RandomWord(english: "grandma", translation: "бабушка"),
            RandomWord(english: "grandpa", translation: "дедушка"),
            RandomWord(english: "arm", translation: "рука"),
            RandomWord(english: "leg", translation: "нога"),
            RandomWord(english: "nose", translation: "нос"),
            RandomWord(english: "eye", translation: "глаз"),
            RandomWord(english: "family", translation: "семья"),
            RandomWord(english: "dog", translation: "собака"),
            RandomWord(english: "cat", translation: "кошка"),
        ])
        // STARTER LEVEL (6 months - 1 year)
        let starterSet = RandomWordSet(name: "Starter (10 words)", words: [
            RandomWord(english: "mama", translation: "мама"),
            RandomWord(english: "papa", translation: "папа"),
            RandomWord(english: "baby", translation: "малыш"),
            RandomWord(english: "milk", translation: "молоко"),
            RandomWord(english: "water", translation: "вода"),
            RandomWord(english: "yes", translation: "да"),
            RandomWord(english: "no", translation: "нет"),
            RandomWord(english: "bye", translation: "пока"),
            RandomWord(english: "hi", translation: "привет"),
            RandomWord(english: "love", translation: "любовь"),
        ])

        // EASY LEVEL (1-2 years)
        let animalsEasySet = RandomWordSet(name: "Animals - Easy (10 words)", words: [
            RandomWord(english: "cat", translation: "кошка"),
            RandomWord(english: "dog", translation: "собака"),
            RandomWord(english: "bird", translation: "птица"),
            RandomWord(english: "fish", translation: "рыба"),
            RandomWord(english: "cow", translation: "корова"),
            RandomWord(english: "duck", translation: "утка"),
            RandomWord(english: "pig", translation: "свинья"),
            RandomWord(english: "rabbit", translation: "кролик"),
            RandomWord(english: "mouse", translation: "мышь"),
            RandomWord(english: "bear", translation: "медведь"),
        ])

        let foodEasySet = RandomWordSet(name: "Food - Easy (10 words)", words: [
            RandomWord(english: "apple", translation: "яблоко"),
            RandomWord(english: "banana", translation: "банан"),
            RandomWord(english: "bread", translation: "хлеб"),
            RandomWord(english: "cookie", translation: "печенье"),
            RandomWord(english: "juice", translation: "сок"),
            RandomWord(english: "egg", translation: "яйцо"),
            RandomWord(english: "cheese", translation: "сыр"),
            RandomWord(english: "cake", translation: "торт"),
            RandomWord(english: "soup", translation: "суп"),
            RandomWord(english: "tea", translation: "чай"),
        ])

        let bodyPartsSet = RandomWordSet(name: "Body Parts (12 words)", words: [
            RandomWord(english: "head", translation: "голова"),
            RandomWord(english: "eye", translation: "глаз"),
            RandomWord(english: "nose", translation: "нос"),
            RandomWord(english: "mouth", translation: "рот"),
            RandomWord(english: "ear", translation: "ухо"),
            RandomWord(english: "hand", translation: "рука"),
            RandomWord(english: "finger", translation: "палец"),
            RandomWord(english: "leg", translation: "нога"),
            RandomWord(english: "foot", translation: "ступня"),
            RandomWord(english: "belly", translation: "живот"),
            RandomWord(english: "hair", translation: "волосы"),
            RandomWord(english: "tooth", translation: "зуб"),
        ])

        let colorsSet = RandomWordSet(name: "Colors (11 words)", words: [
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

        let actionsEasySet = RandomWordSet(name: "Actions - Easy (10 words)", words: [
            RandomWord(english: "eat", translation: "есть"),
            RandomWord(english: "drink", translation: "пить"),
            RandomWord(english: "sleep", translation: "спать"),
            RandomWord(english: "walk", translation: "ходить"),
            RandomWord(english: "run", translation: "бегать"),
            RandomWord(english: "jump", translation: "прыгать"),
            RandomWord(english: "play", translation: "играть"),
            RandomWord(english: "sit", translation: "сидеть"),
            RandomWord(english: "stand", translation: "стоять"),
            RandomWord(english: "look", translation: "смотреть"),
        ])

        // MEDIUM LEVEL (2-3 years)
        let animalsMediumSet = RandomWordSet(name: "Animals - Medium (15 words)", words: [
            RandomWord(english: "horse", translation: "лошадь"),
            RandomWord(english: "sheep", translation: "овца"),
            RandomWord(english: "chicken", translation: "курица"),
            RandomWord(english: "lion", translation: "лев"),
            RandomWord(english: "tiger", translation: "тигр"),
            RandomWord(english: "elephant", translation: "слон"),
            RandomWord(english: "giraffe", translation: "жираф"),
            RandomWord(english: "monkey", translation: "обезьяна"),
            RandomWord(english: "zebra", translation: "зебра"),
            RandomWord(english: "frog", translation: "лягушка"),
            RandomWord(english: "butterfly", translation: "бабочка"),
            RandomWord(english: "snake", translation: "змея"),
            RandomWord(english: "turtle", translation: "черепаха"),
            RandomWord(english: "penguin", translation: "пингвин"),
            RandomWord(english: "owl", translation: "сова"),
        ])

        let foodMediumSet = RandomWordSet(name: "Food - Medium (15 words)", words: [
            RandomWord(english: "orange", translation: "апельсин"),
            RandomWord(english: "grape", translation: "виноград"),
            RandomWord(english: "strawberry", translation: "клубника"),
            RandomWord(english: "watermelon", translation: "арбуз"),
            RandomWord(english: "carrot", translation: "морковь"),
            RandomWord(english: "potato", translation: "картошка"),
            RandomWord(english: "tomato", translation: "помидор"),
            RandomWord(english: "cucumber", translation: "огурец"),
            RandomWord(english: "ice cream", translation: "мороженое"),
            RandomWord(english: "pizza", translation: "пицца"),
            RandomWord(english: "pasta", translation: "паста"),
            RandomWord(english: "rice", translation: "рис"),
            RandomWord(english: "meat", translation: "мясо"),
            RandomWord(english: "chicken", translation: "курица"),
            RandomWord(english: "sandwich", translation: "бутерброд"),
        ])

        let toysSet = RandomWordSet(name: "Toys & Play (12 words)", words: [
            RandomWord(english: "ball", translation: "мяч"),
            RandomWord(english: "doll", translation: "кукла"),
            RandomWord(english: "teddy bear", translation: "плюшевый мишка"),
            RandomWord(english: "car", translation: "машинка"),
            RandomWord(english: "train", translation: "поезд"),
            RandomWord(english: "bike", translation: "велосипед"),
            RandomWord(english: "block", translation: "кубик"),
            RandomWord(english: "puzzle", translation: "пазл"),
            RandomWord(english: "book", translation: "книга"),
            RandomWord(english: "swing", translation: "качели"),
            RandomWord(english: "slide", translation: "горка"),
            RandomWord(english: "drum", translation: "барабан"),
        ])

        let natureSet = RandomWordSet(name: "Nature (12 words)", words: [
            RandomWord(english: "sun", translation: "солнце"),
            RandomWord(english: "moon", translation: "луна"),
            RandomWord(english: "star", translation: "звезда"),
            RandomWord(english: "cloud", translation: "облако"),
            RandomWord(english: "rain", translation: "дождь"),
            RandomWord(english: "snow", translation: "снег"),
            RandomWord(english: "tree", translation: "дерево"),
            RandomWord(english: "flower", translation: "цветок"),
            RandomWord(english: "grass", translation: "трава"),
            RandomWord(english: "water", translation: "вода"),
            RandomWord(english: "sky", translation: "небо"),
            RandomWord(english: "wind", translation: "ветер"),
        ])

        let actionsMediumSet = RandomWordSet(name: "Actions - Medium (12 words)", words: [
            RandomWord(english: "dance", translation: "танцевать"),
            RandomWord(english: "sing", translation: "петь"),
            RandomWord(english: "read", translation: "читать"),
            RandomWord(english: "draw", translation: "рисовать"),
            RandomWord(english: "write", translation: "писать"),
            RandomWord(english: "clap", translation: "хлопать"),
            RandomWord(english: "wave", translation: "махать"),
            RandomWord(english: "hug", translation: "обнимать"),
            RandomWord(english: "kiss", translation: "целовать"),
            RandomWord(english: "laugh", translation: "смеяться"),
            RandomWord(english: "cry", translation: "плакать"),
            RandomWord(english: "smile", translation: "улыбаться"),
        ])

        // ADVANCED LEVEL (3+ years)
        let vehiclesSet = RandomWordSet(name: "Vehicles (10 words)", words: [
            RandomWord(english: "car", translation: "машина"),
            RandomWord(english: "bus", translation: "автобус"),
            RandomWord(english: "truck", translation: "грузовик"),
            RandomWord(english: "train", translation: "поезд"),
            RandomWord(english: "plane", translation: "самолёт"),
            RandomWord(english: "helicopter", translation: "вертолёт"),
            RandomWord(english: "boat", translation: "лодка"),
            RandomWord(english: "ship", translation: "корабль"),
            RandomWord(english: "rocket", translation: "ракета"),
            RandomWord(english: "bicycle", translation: "велосипед"),
        ])

        let familySet = RandomWordSet(name: "Family (10 words)", words: [
            RandomWord(english: "grandma", translation: "бабушка"),
            RandomWord(english: "grandpa", translation: "дедушка"),
            RandomWord(english: "brother", translation: "брат"),
            RandomWord(english: "sister", translation: "сестра"),
            RandomWord(english: "aunt", translation: "тётя"),
            RandomWord(english: "uncle", translation: "дядя"),
            RandomWord(english: "cousin", translation: "двоюродный брат"),
            RandomWord(english: "friend", translation: "друг"),
            RandomWord(english: "family", translation: "семья"),
            RandomWord(english: "home", translation: "дом"),
        ])

        return [
            basicSet,
            starterSet,
            animalsEasySet, foodEasySet, bodyPartsSet, colorsSet, actionsEasySet,
            animalsMediumSet, foodMediumSet, toysSet, natureSet, actionsMediumSet,
            vehiclesSet, familySet
        ]
    }
    
    func getRandomWord() -> RandomWord? {
        // If baby name is set, include it in the random selection based on configured probability
        if !babyName.isEmpty && Double.random(in: 0.0...1.0) < babyNameProbability {
            let translation = babyNameTranslation.isEmpty ? babyName : babyNameTranslation
            return RandomWord(english: babyName, translation: translation)
        }

        guard !words.isEmpty else { return nil }
        return words.randomElement()
    }
    
    func findWord(english: String) -> RandomWord? {
        if english.lowercased() == babyName.lowercased() {
            let translation = babyNameTranslation.isEmpty ? babyName : babyNameTranslation
            return RandomWord(english: babyName, translation: translation)
        }
        return words.first { $0.english.lowercased() == english.lowercased() }
    }
    
    func updateWordSet(at index: Int, newWords: [RandomWord]) {
        guard index >= 0 && index < wordSets.count else { return }
        let currentSetName = wordSets[index].name
        wordSets[index] = RandomWordSet(name: currentSetName, words: newWords)
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
        // Remove from enabled sets if it was enabled
        enabledSetIndices.remove(index)
        // Adjust indices for sets that were after the deleted one
        let adjustedIndices = enabledSetIndices.compactMap { oldIndex -> Int? in
            if oldIndex > index {
                return oldIndex - 1
            } else if oldIndex == index {
                return nil
            } else {
                return oldIndex
            }
        }
        enabledSetIndices = Set(adjustedIndices)
        saveWordSets()
        saveEnabledSets()
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

    func setBabyNameTranslation(_ translation: String) {
        babyNameTranslation = translation
        saveBabyNameTranslation()
        NotificationCenter.default.post(name: .init("BabyNameUpdated"), object: nil)
    }

    func setBabyNameProbability(_ probability: Double) {
        babyNameProbability = max(0.0, min(1.0, probability)) // Clamp between 0 and 1
        saveBabyNameProbability()
    }

    func setBabyImagePath(_ path: String) {
        babyImagePath = path
        saveBabyImagePath()
        NotificationCenter.default.post(name: .init("BabyImageUpdated"), object: nil)
    }

    func setBabyImageURL(_ url: URL) {
        babyImagePath = url.path

        // Create security-scoped bookmark for sandboxed access
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            babyImageBookmark = bookmarkData
            UserDefaults.standard.set(bookmarkData, forKey: babyImageBookmarkKey)
        } catch {
            debugPrint("Failed to create bookmark for baby image: \(error)")
            babyImageBookmark = nil
        }

        saveBabyImagePath()
        NotificationCenter.default.post(name: .init("BabyImageUpdated"), object: nil)
    }

    func getBabyImageURL() -> URL? {
        // Try to resolve from security-scoped bookmark first
        if let bookmarkData = babyImageBookmark {
            var isStale = false
            do {
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                if isStale {
                    debugPrint("Baby image bookmark is stale, recreating...")
                    // Try to recreate the bookmark
                    if let newBookmarkData = try? url.bookmarkData(
                        options: .withSecurityScope,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    ) {
                        babyImageBookmark = newBookmarkData
                        UserDefaults.standard.set(newBookmarkData, forKey: babyImageBookmarkKey)
                    }
                }

                return url
            } catch {
                debugPrint("Failed to resolve baby image bookmark: \(error)")
            }
        }

        // Fallback to path-based access (for non-sandboxed or development)
        if !babyImagePath.isEmpty {
            return URL(fileURLWithPath: babyImagePath)
        }

        return nil
    }

    func resetToDefaults() {
        // Reset wordsets to defaults
        wordSets = createDefaultWordSets()
        // Enable only the first set (Basic Words)
        enabledSetIndices = [0]
        // Save changes
        saveWordSets()
        saveEnabledSets()
        // Note: babyName and babyNameProbability are preserved
        objectWillChange.send()
        NotificationCenter.default.post(name: .init("RandomWordSetChanged"), object: nil)
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

    private func saveEnabledSets() {
        let array = Array(enabledSetIndices)
        if let encoded = try? JSONEncoder().encode(array) {
            UserDefaults.standard.set(encoded, forKey: enabledSetsKey)
        }
    }

    private func loadEnabledSets() {
        // Try to load enabled sets
        if let savedData = UserDefaults.standard.data(forKey: enabledSetsKey),
           let decodedArray = try? JSONDecoder().decode([Int].self, from: savedData) {
            enabledSetIndices = Set(decodedArray)
            return
        }

        // Migrate from old selectedSetIndexKey
        let oldIndex = UserDefaults.standard.integer(forKey: "selectedRandomWordSetIndex")
        if oldIndex >= 0 && oldIndex < wordSets.count {
            enabledSetIndices = [oldIndex]
            saveEnabledSets()
        }
    }

    private func saveBabyName() {
        UserDefaults.standard.set(babyName, forKey: babyNameKey)
    }

    private func loadBabyName() {
        babyName = UserDefaults.standard.string(forKey: babyNameKey) ?? ""
    }

    private func saveBabyNameTranslation() {
        UserDefaults.standard.set(babyNameTranslation, forKey: babyNameTranslationKey)
    }

    private func loadBabyNameTranslation() {
        babyNameTranslation = UserDefaults.standard.string(forKey: babyNameTranslationKey) ?? ""
    }

    private func saveBabyNameProbability() {
        UserDefaults.standard.set(babyNameProbability, forKey: babyNameProbabilityKey)
    }

    private func loadBabyNameProbability() {
        let savedProbability = UserDefaults.standard.double(forKey: babyNameProbabilityKey)
        // If no value is saved (returns 0), use default
        if savedProbability == 0 && !UserDefaults.standard.dictionaryRepresentation().keys.contains(babyNameProbabilityKey) {
            babyNameProbability = 0.125 // Default 12.5%
        } else {
            babyNameProbability = savedProbability
        }
    }

    private func saveBabyImagePath() {
        UserDefaults.standard.set(babyImagePath, forKey: babyImagePathKey)
    }

    private func loadBabyImagePath() {
        babyImagePath = UserDefaults.standard.string(forKey: babyImagePathKey) ?? ""
        babyImageBookmark = UserDefaults.standard.data(forKey: babyImageBookmarkKey)
    }

    // MARK: - Custom Word Images Management

    func setCustomWordImage(word: String, url: URL) {
        // Remove existing image for this word if any
        customWordImages.removeAll { $0.word.lowercased() == word.lowercased() }

        // Add new image
        let customImage = CustomWordImage(word: word, imagePath: url.path)
        customWordImages.append(customImage)

        // Create security-scoped bookmark
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            customWordImageBookmarks[word.lowercased()] = bookmarkData
            saveCustomWordImageBookmarks()
        } catch {
            debugPrint("Failed to create bookmark for custom image: \(error)")
        }

        saveCustomWordImages()
        NotificationCenter.default.post(name: .init("CustomWordImagesUpdated"), object: nil)
    }

    func removeCustomWordImage(word: String) {
        customWordImages.removeAll { $0.word.lowercased() == word.lowercased() }
        customWordImageBookmarks.removeValue(forKey: word.lowercased())
        saveCustomWordImages()
        saveCustomWordImageBookmarks()
        NotificationCenter.default.post(name: .init("CustomWordImagesUpdated"), object: nil)
    }

    func getCustomImageURL(for word: String) -> URL? {
        let lowercasedWord = word.lowercased()

        // Try to resolve from security-scoped bookmark first
        if let bookmarkData = customWordImageBookmarks[lowercasedWord] {
            var isStale = false
            do {
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                if isStale {
                    debugPrint("Custom image bookmark is stale for '\(word)', recreating...")
                    // Try to recreate the bookmark
                    if let newBookmarkData = try? url.bookmarkData(
                        options: .withSecurityScope,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    ) {
                        customWordImageBookmarks[lowercasedWord] = newBookmarkData
                        saveCustomWordImageBookmarks()
                    }
                }

                return url
            } catch {
                debugPrint("Failed to resolve custom image bookmark for '\(word)': \(error)")
            }
        }

        // Fallback to path-based access
        if let customImage = customWordImages.first(where: { $0.word.lowercased() == lowercasedWord }) {
            if !customImage.imagePath.isEmpty {
                return URL(fileURLWithPath: customImage.imagePath)
            }
        }

        return nil
    }

    private func saveCustomWordImages() {
        if let encoded = try? JSONEncoder().encode(customWordImages) {
            UserDefaults.standard.set(encoded, forKey: customWordImagesKey)
        }
    }

    private func loadCustomWordImages() {
        if let savedImages = UserDefaults.standard.data(forKey: customWordImagesKey),
           let decodedImages = try? JSONDecoder().decode([CustomWordImage].self, from: savedImages) {
            customWordImages = decodedImages
        }

        if let savedBookmarks = UserDefaults.standard.data(forKey: customWordImageBookmarksKey),
           let decodedBookmarks = try? JSONDecoder().decode([String: Data].self, from: savedBookmarks) {
            customWordImageBookmarks = decodedBookmarks
        }
    }

    private func saveCustomWordImageBookmarks() {
        if let encoded = try? JSONEncoder().encode(customWordImageBookmarks) {
            UserDefaults.standard.set(encoded, forKey: customWordImageBookmarksKey)
        }
    }
} 