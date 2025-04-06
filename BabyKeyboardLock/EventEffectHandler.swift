//
//  Event.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//
import Cocoa
import Carbon
import AVFoundation
import Foundation
import CoreGraphics
import Sauce

extension CGEventFlags {
    var toNSEventModifierFlags: NSEvent.ModifierFlags {
        var nsFlags = NSEvent.ModifierFlags()
        
        if contains(.maskShift) {
            nsFlags.insert(.shift)
        }
        if contains(.maskControl) {
            nsFlags.insert(.control)
        }
        if contains(.maskAlternate) {
            nsFlags.insert(.option)
        }
        if contains(.maskCommand) {
            nsFlags.insert(.command)
        }
        if contains(.maskNumericPad) {
            nsFlags.insert(.numericPad)
        }
        if contains(.maskSecondaryFn) {
            nsFlags.insert(.function)
        }
        if contains(.maskAlphaShift) {
            nsFlags.insert(.capsLock)
        }
        
        return nsFlags
    }
}

class EventEffectHandler {
    let simpleWordsMap: [String: [String]] = [
        "a": ["apple", "ant", "air", "arm", "axe", "all", "ask", "and", "add"],
        "b": ["ball", "bat", "bag", "bed", "bear", "bug", "bun", "bus", "big", "bit"],
        "c": ["cat", "car", "cow", "cup", "cap", "can", "cut", "cry", "corn"],
        "d": ["dog", "duck", "dot", "dig", "doll", "dip", "day", "den", "dam"],
        "e": ["egg", "ear", "eat", "end", "eye", "elf", "eel", "edge", "easy"],
        "f": ["fish", "fan", "fog", "fat", "fit", "fig", "fun", "far", "fox"],
        "g": ["goat", "gum", "gap", "got", "gun", "gas", "gut", "gig", "go"],
        "h": ["hat", "hen", "hop", "hit", "hug", "hot", "hip", "hum", "hut"],
        "i": ["ice", "ink", "igloo", "ill", "inn", "it", "is", "if", "in"],
        "j": ["jam", "jug", "jet", "job", "jog", "jaw", "joy", "jump", "jot"],
        "k": ["kite", "key", "kid", "kit", "king", "kick", "kind", "keep", "kitty"],
        "l": ["lion", "leg", "lip", "lap", "log", "let", "lot", "low", "lid"],
        "m": ["moon", "man", "map", "mug", "mat", "mix", "mud", "mom", "me", "mad"],
        "n": ["nest", "net", "nap", "nut", "nod", "new", "not", "no", "nice"],
        "o": ["owl", "ox", "oil", "odd", "off", "old", "on", "out", "oak"],
        "p": ["pig", "pen", "pot", "pan", "pet", "pin", "pop", "pit", "pat"],
        "q": ["queen", "quilt", "quiz", "quick", "quit", "quack", "quest"],
        "r": ["rat", "rug", "run", "red", "row", "rip", "rob", "ram", "rod"],
        "s": ["sun", "sit", "sip", "sad", "sow", "set", "saw", "sea", "six"],
        "t": ["top", "tap", "tin", "toy", "tip", "tag", "tub", "tan", "ten"],
        "u": ["umbrella", "up", "use", "us", "urn", "ugly", "unit"],
        "v": ["van", "vet", "vase", "vat", "vie", "via", "vest", "vivid"],
        "w": ["wet", "win", "wig", "wax", "way", "wow", "web", "was", "will"],
        "x": ["x-ray", "xylophone", "xenon"],
        "y": ["yak", "yes", "yarn", "yell", "yet", "yum", "you", "young"],
        "z": ["zebra", "zip", "zap", "zig", "zoo", "zen", "zero", "zone"]
    ]
    
    // Translation dictionaries for supported languages
    let frenchTranslations: [String: String] = [
        "apple": "pomme", "ant": "fourmi", "air": "air", "arm": "bras", "axe": "hache", "all": "tous", "ask": "demander", "and": "et", "add": "ajouter",
        "ball": "balle", "bat": "chauve-souris", "bag": "sac", "bed": "lit", "bear": "ours", "bug": "insecte", "bun": "petit pain", "bus": "bus", "big": "grand", "bit": "morceau",
        "cat": "chat", "car": "voiture", "cow": "vache", "cup": "tasse", "cap": "casquette", "can": "peut", "cut": "couper", "cry": "pleurer", "corn": "maïs",
        "dog": "chien", "duck": "canard", "dot": "point", "dig": "creuser", "doll": "poupée", "dip": "tremper", "day": "jour", "den": "tanière", "dam": "barrage",
        "egg": "œuf", "ear": "oreille", "eat": "manger", "end": "fin", "eye": "œil", "elf": "elfe", "eel": "anguille", "edge": "bord", "easy": "facile",
        "fish": "poisson", "fan": "ventilateur", "fog": "brouillard", "fat": "gras", "fit": "adapter", "fig": "figue", "fun": "amusement", "far": "loin", "fox": "renard",
        "goat": "chèvre", "gum": "gomme", "gap": "écart", "got": "obtenu", "gun": "pistolet", "gas": "gaz", "gut": "intestin", "gig": "concert", "go": "aller",
        "hat": "chapeau", "hen": "poule", "hop": "saut", "hit": "frapper", "hug": "câlin", "hot": "chaud", "hip": "hanche", "hum": "fredonner", "hut": "cabane",
        "ice": "glace", "ink": "encre", "igloo": "igloo", "ill": "malade", "inn": "auberge", "it": "il", "is": "est", "if": "si", "in": "dans",
        "jam": "confiture", "jug": "cruche", "jet": "jet", "job": "travail", "jog": "jogging", "jaw": "mâchoire", "joy": "joie", "jump": "sauter", "jot": "noter",
        "kite": "cerf-volant", "key": "clé", "kid": "enfant", "kit": "kit", "king": "roi", "kick": "coup de pied", "kind": "gentil", "keep": "garder", "kitty": "chaton",
        "lion": "lion", "leg": "jambe", "lip": "lèvre", "lap": "tour", "log": "bûche", "let": "laisser", "lot": "beaucoup", "low": "bas", "lid": "couvercle",
        "moon": "lune", "man": "homme", "map": "carte", "mug": "tasse", "mat": "tapis", "mix": "mélange", "mud": "boue", "mom": "maman", "me": "moi", "mad": "fou",
        "nest": "nid", "net": "filet", "nap": "sieste", "nut": "noix", "nod": "hochement", "new": "nouveau", "not": "pas", "no": "non", "nice": "gentil",
        "owl": "hibou", "ox": "bœuf", "oil": "huile", "odd": "impair", "off": "éteint", "old": "vieux", "on": "sur", "out": "dehors", "oak": "chêne",
        "pig": "cochon", "pen": "stylo", "pot": "pot", "pan": "poêle", "pet": "animal", "pin": "épingle", "pop": "pop", "pit": "fosse", "pat": "tapotement",
        "queen": "reine", "quilt": "couette", "quiz": "quiz", "quick": "rapide", "quit": "quitter", "quack": "coin-coin", "quest": "quête",
        "rat": "rat", "rug": "tapis", "run": "courir", "red": "rouge", "row": "rangée", "rip": "déchirer", "rob": "voler", "ram": "bélier", "rod": "tige",
        "sun": "soleil", "sit": "s'asseoir", "sip": "siroter", "sad": "triste", "sow": "semer", "set": "ensemble", "saw": "scie", "sea": "mer", "six": "six",
        "top": "haut", "tap": "robinet", "tin": "étain", "toy": "jouet", "tip": "pourboire", "tag": "étiquette", "tub": "baignoire", "tan": "bronzage", "ten": "dix",
        "umbrella": "parapluie", "up": "haut", "use": "utiliser", "us": "nous", "urn": "urne", "ugly": "laid", "unit": "unité",
        "van": "fourgon", "vet": "vétérinaire", "vase": "vase", "vat": "cuve", "vie": "rivaliser", "via": "via", "vest": "gilet", "vivid": "vif",
        "wet": "mouillé", "win": "gagner", "wig": "perruque", "wax": "cire", "way": "chemin", "wow": "ouah", "web": "toile", "was": "était", "will": "volonté",
        "x-ray": "rayon-x", "xylophone": "xylophone", "xenon": "xénon",
        "yak": "yack", "yes": "oui", "yarn": "fil", "yell": "crier", "yet": "encore", "yum": "miam", "you": "toi", "young": "jeune",
        "zebra": "zèbre", "zip": "fermeture éclair", "zap": "zapper", "zig": "zigzag", "zoo": "zoo", "zen": "zen", "zero": "zéro", "zone": "zone"
    ]
    
    let russianTranslations: [String: String] = [
        "apple": "яблоко", "ant": "муравей", "air": "воздух", "arm": "рука", "axe": "топор", "all": "все", "ask": "спрашивать", "and": "и", "add": "добавить",
        "ball": "мяч", "bat": "летучая мышь", "bag": "сумка", "bed": "кровать", "bear": "медведь", "bug": "жук", "bun": "булочка", "bus": "автобус", "big": "большой", "bit": "кусочек",
        "cat": "кот", "car": "машина", "cow": "корова", "cup": "чашка", "cap": "кепка", "can": "может", "cut": "резать", "cry": "плакать", "corn": "кукуруза",
        "dog": "собака", "duck": "утка", "dot": "точка", "dig": "копать", "doll": "кукла", "dip": "окунать", "day": "день", "den": "логово", "dam": "плотина",
        "egg": "яйцо", "ear": "ухо", "eat": "есть", "end": "конец", "eye": "глаз", "elf": "эльф", "eel": "угорь", "edge": "край", "easy": "легко",
        "fish": "рыба", "fan": "вентилятор", "fog": "туман", "fat": "жир", "fit": "подходить", "fig": "инжир", "fun": "веселье", "far": "далеко", "fox": "лиса",
        "goat": "коза", "gum": "жвачка", "gap": "разрыв", "got": "получил", "gun": "пистолет", "gas": "газ", "gut": "кишка", "gig": "концерт", "go": "идти",
        "hat": "шляпа", "hen": "курица", "hop": "прыжок", "hit": "удар", "hug": "объятие", "hot": "горячий", "hip": "бедро", "hum": "гудеть", "hut": "хижина",
        "ice": "лед", "ink": "чернила", "igloo": "иглу", "ill": "больной", "inn": "гостиница", "it": "оно", "is": "есть", "if": "если", "in": "в",
        "jam": "варенье", "jug": "кувшин", "jet": "реактивный", "job": "работа", "jog": "бег", "jaw": "челюсть", "joy": "радость", "jump": "прыгать", "jot": "записывать",
        "kite": "воздушный змей", "key": "ключ", "kid": "ребенок", "kit": "набор", "king": "король", "kick": "удар ногой", "kind": "добрый", "keep": "хранить", "kitty": "котенок",
        "lion": "лев", "leg": "нога", "lip": "губа", "lap": "колени", "log": "бревно", "let": "позволять", "lot": "много", "low": "низкий", "lid": "крышка",
        "moon": "луна", "man": "человек", "map": "карта", "mug": "кружка", "mat": "коврик", "mix": "смесь", "mud": "грязь", "mom": "мама", "me": "я", "mad": "сумасшедший",
        "nest": "гнездо", "net": "сеть", "nap": "дремота", "nut": "орех", "nod": "кивок", "new": "новый", "not": "не", "no": "нет", "nice": "хороший",
        "owl": "сова", "ox": "бык", "oil": "масло", "odd": "нечетный", "off": "выключено", "old": "старый", "on": "на", "out": "вне", "oak": "дуб",
        "pig": "свинья", "pen": "ручка", "pot": "горшок", "pan": "сковорода", "pet": "питомец", "pin": "булавка", "pop": "хлопок", "pit": "яма", "pat": "похлопывание",
        "queen": "королева", "quilt": "одеяло", "quiz": "викторина", "quick": "быстрый", "quit": "выход", "quack": "кря", "quest": "поиск",
        "rat": "крыса", "rug": "ковер", "run": "бежать", "red": "красный", "row": "ряд", "rip": "рвать", "rob": "грабить", "ram": "баран", "rod": "стержень",
        "sun": "солнце", "sit": "сидеть", "sip": "потягивать", "sad": "грустный", "sow": "сеять", "set": "набор", "saw": "пила", "sea": "море", "six": "шесть",
        "top": "верх", "tap": "кран", "tin": "олово", "toy": "игрушка", "tip": "совет", "tag": "метка", "tub": "ванна", "tan": "загар", "ten": "десять",
        "umbrella": "зонт", "up": "вверх", "use": "использовать", "us": "мы", "urn": "урна", "ugly": "уродливый", "unit": "единица",
        "van": "фургон", "vet": "ветеринар", "vase": "ваза", "vat": "чан", "vie": "соперничать", "via": "через", "vest": "жилет", "vivid": "яркий",
        "wet": "мокрый", "win": "выигрыш", "wig": "парик", "wax": "воск", "way": "путь", "wow": "вау", "web": "паутина", "was": "был", "will": "воля",
        "x-ray": "рентген", "xylophone": "ксилофон", "xenon": "ксенон",
        "yak": "як", "yes": "да", "yarn": "пряжа", "yell": "кричать", "yet": "еще", "yum": "вкусно", "you": "ты", "young": "молодой",
        "zebra": "зебра", "zip": "застежка", "zap": "бить", "zig": "зигзаг", "zoo": "зоопарк", "zen": "дзен", "zero": "ноль", "zone": "зона"
    ]
    
    let germanTranslations: [String: String] = [
        "apple": "Apfel", "ant": "Ameise", "air": "Luft", "arm": "Arm", "axe": "Axt", "all": "alle", "ask": "fragen", "and": "und", "add": "hinzufügen",
        "ball": "Ball", "bat": "Fledermaus", "bag": "Tasche", "bed": "Bett", "bear": "Bär", "bug": "Käfer", "bun": "Brötchen", "bus": "Bus", "big": "groß", "bit": "Stück",
        "cat": "Katze", "car": "Auto", "cow": "Kuh", "cup": "Tasse", "cap": "Mütze", "can": "kann", "cut": "schneiden", "cry": "weinen", "corn": "Mais",
        "dog": "Hund", "duck": "Ente", "dot": "Punkt", "dig": "graben", "doll": "Puppe", "dip": "eintauchen", "day": "Tag", "den": "Höhle", "dam": "Damm",
        "egg": "Ei", "ear": "Ohr", "eat": "essen", "end": "Ende", "eye": "Auge", "elf": "Elf", "eel": "Aal", "edge": "Kante", "easy": "einfach",
        "fish": "Fisch", "fan": "Ventilator", "fog": "Nebel", "fat": "Fett", "fit": "passen", "fig": "Feige", "fun": "Spaß", "far": "weit", "fox": "Fuchs",
        "goat": "Ziege", "gum": "Kaugummi", "gap": "Lücke", "got": "bekommen", "gun": "Pistole", "gas": "Gas", "gut": "Darm", "gig": "Konzert", "go": "gehen",
        "hat": "Hut", "hen": "Henne", "hop": "Sprung", "hit": "Treffer", "hug": "Umarmung", "hot": "heiß", "hip": "Hüfte", "hum": "summen", "hut": "Hütte",
        "ice": "Eis", "ink": "Tinte", "igloo": "Iglu", "ill": "krank", "inn": "Gasthaus", "it": "es", "is": "ist", "if": "wenn", "in": "in",
        "jam": "Marmelade", "jug": "Krug", "jet": "Düsenflugzeug", "job": "Arbeit", "jog": "Joggen", "jaw": "Kiefer", "joy": "Freude", "jump": "springen", "jot": "notieren",
        "kite": "Drachen", "key": "Schlüssel", "kid": "Kind", "kit": "Set", "king": "König", "kick": "Tritt", "kind": "nett", "keep": "behalten", "kitty": "Kätzchen",
        "lion": "Löwe", "leg": "Bein", "lip": "Lippe", "lap": "Schoß", "log": "Baumstamm", "let": "lassen", "lot": "Menge", "low": "niedrig", "lid": "Deckel",
        "moon": "Mond", "man": "Mann", "map": "Karte", "mug": "Becher", "mat": "Matte", "mix": "Mischung", "mud": "Schlamm", "mom": "Mama", "me": "ich", "mad": "verrückt",
        "nest": "Nest", "net": "Netz", "nap": "Nickerchen", "nut": "Nuss", "nod": "nicken", "new": "neu", "not": "nicht", "no": "nein", "nice": "nett",
        "owl": "Eule", "ox": "Ochse", "oil": "Öl", "odd": "ungerade", "off": "aus", "old": "alt", "on": "an", "out": "aus", "oak": "Eiche",
        "pig": "Schwein", "pen": "Stift", "pot": "Topf", "pan": "Pfanne", "pet": "Haustier", "pin": "Stecknadel", "pop": "knallen", "pit": "Grube", "pat": "Klopfer",
        "queen": "Königin", "quilt": "Steppdecke", "quiz": "Quiz", "quick": "schnell", "quit": "beenden", "quack": "quak", "quest": "Suche",
        "rat": "Ratte", "rug": "Teppich", "run": "laufen", "red": "rot", "row": "Reihe", "rip": "reißen", "rob": "rauben", "ram": "Widder", "rod": "Stange",
        "sun": "Sonne", "sit": "sitzen", "sip": "nippen", "sad": "traurig", "sow": "säen", "set": "Set", "saw": "Säge", "sea": "Meer", "six": "sechs",
        "top": "Spitze", "tap": "Wasserhahn", "tin": "Zinn", "toy": "Spielzeug", "tip": "Tipp", "tag": "Etikett", "tub": "Wanne", "tan": "Bräune", "ten": "zehn",
        "umbrella": "Regenschirm", "up": "oben", "use": "benutzen", "us": "uns", "urn": "Urne", "ugly": "hässlich", "unit": "Einheit",
        "van": "Lieferwagen", "vet": "Tierarzt", "vase": "Vase", "vat": "Fass", "vie": "wetteifern", "via": "über", "vest": "Weste", "vivid": "lebendig",
        "wet": "nass", "win": "gewinnen", "wig": "Perücke", "wax": "Wachs", "way": "Weg", "wow": "wow", "web": "Netz", "was": "war", "will": "Wille",
        "x-ray": "Röntgen", "xylophone": "Xylophon", "xenon": "Xenon",
        "yak": "Yak", "yes": "ja", "yarn": "Garn", "yell": "schreien", "yet": "noch", "yum": "lecker", "you": "du", "young": "jung",
        "zebra": "Zebra", "zip": "Reißverschluss", "zap": "zappen", "zig": "Zickzack", "zoo": "Zoo", "zen": "Zen", "zero": "null", "zone": "Zone"
    ]
    
    let synth = AVSpeechSynthesizer()
    var translationLanguage: TranslationLanguage = .none
    
    func handle(event: CGEvent, eventType: CGEventType, selectedLockEffect: LockEffect) -> String {
        debugPrint("speaking handle ------- \(selectedLockEffect)")
        // guard eventType == .keyUp else { return }
        guard let str = getString(event: event, eventType: eventType) else { return "" }
        debugPrint("get key name ------- \(str)")
 
       
        switch selectedLockEffect {
        case .speakTheKey:
            DispatchQueue.global(qos: .background).async {
                self.synth.speak(self.createUtterance(for: str))
            }
        case .speakAKeyWord:
            let randomWord = getRandomWord(forKey: str)
            DispatchQueue.global(qos: .background).async {
                self.synth.speak(self.createUtterance(for: randomWord))
                
                // If translation is enabled, speak the translation after a short delay
                if self.translationLanguage != .none {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        if let translatedWord = self.getTranslation(word: randomWord, language: self.translationLanguage) {
                            self.synth.speak(self.createUtterance(for: translatedWord, language: self.translationLanguage.languageCode))
                        }
                    }
                }
            }
            return randomWord
        default:
            break
        }
        
        return str
    }
    
    func getString(event: CGEvent, eventType: CGEventType) -> String? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if KeyCode.allCases.contains(where: { $0.rawValue == keyCode }) {
            return String(describing: KeyCode(rawValue: CGKeyCode(keyCode))!)
        }
        
        return Sauce.shared.character(
            for: Int(event.getIntegerValueField(.keyboardEventKeycode)),
            cocoaModifiers: event.flags.toNSEventModifierFlags
        )
    }
    
    func getRandomWord(forKey key: String) -> String {
        let key = key.lowercased()
        // debugPrint("getWord ------- \(key) -- \(wordCache[key])")
        guard let words = simpleWordsMap[key],
              let randomWord = words.randomElement() else {
            return key
        }
        
        debugPrint("getWord ------- \(key) -- \(randomWord)")
        return randomWord
    }
    
    private func createUtterance(for str: String, language: String? = nil) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: str)
        // utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.1
        
        let languageCode = language ?? Locale.preferredLanguages[0]
        
        // https://stackoverflow.com/questions/37512621/avspeechsynthesizer-change-voice
        let allVoices = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            guard languageCode == voice.language else { return false}
            // debugPrint("speaking ------- \(voice.identifier)")
            return true
        }
        utterance.voice = allVoices.first {voice in voice.identifier.contains("siri") } ?? allVoices.first
        
        return utterance
    }
    
    // Get translation for a word based on the selected language
    func getTranslation(word: String, language: TranslationLanguage) -> String? {
        switch language {
        case .french:
            return frenchTranslations[word.lowercased()]
        case .russian: 
            return russianTranslations[word.lowercased()]
        case .german:
            return germanTranslations[word.lowercased()]
        case .none:
            return nil
        }
    }
}
