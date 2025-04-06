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
    
    let spanishTranslations: [String: String] = [
        "apple": "manzana", "ant": "hormiga", "air": "aire", "arm": "brazo", "axe": "hacha", "all": "todo", "ask": "preguntar", "and": "y", "add": "añadir",
        "ball": "pelota", "bat": "murciélago", "bag": "bolsa", "bed": "cama", "bear": "oso", "bug": "bicho", "bun": "bollo", "bus": "autobús", "big": "grande", "bit": "pedazo",
        "cat": "gato", "car": "coche", "cow": "vaca", "cup": "taza", "cap": "gorra", "can": "poder", "cut": "cortar", "cry": "llorar", "corn": "maíz",
        "dog": "perro", "duck": "pato", "dot": "punto", "dig": "cavar", "doll": "muñeca", "dip": "mojar", "day": "día", "den": "guarida", "dam": "presa",
        "egg": "huevo", "ear": "oreja", "eat": "comer", "end": "fin", "eye": "ojo", "elf": "elfo", "eel": "anguila", "edge": "borde", "easy": "fácil",
        "fish": "pez", "fan": "ventilador", "fog": "niebla", "fat": "gordo", "fit": "ajustar", "fig": "higo", "fun": "diversión", "far": "lejos", "fox": "zorro",
        "goat": "cabra", "gum": "chicle", "gap": "brecha", "got": "conseguido", "gun": "pistola", "gas": "gas", "gut": "tripa", "gig": "concierto", "go": "ir",
        "hat": "sombrero", "hen": "gallina", "hop": "salto", "hit": "golpear", "hug": "abrazo", "hot": "caliente", "hip": "cadera", "hum": "tararear", "hut": "cabaña",
        "ice": "hielo", "ink": "tinta", "igloo": "iglú", "ill": "enfermo", "inn": "posada", "it": "ello", "is": "es", "if": "si", "in": "en",
        "jam": "mermelada", "jug": "jarra", "jet": "jet", "job": "trabajo", "jog": "trotar", "jaw": "mandíbula", "joy": "alegría", "jump": "saltar", "jot": "anotar",
        "kite": "cometa", "key": "llave", "kid": "niño", "kit": "kit", "king": "rey", "kick": "patada", "kind": "amable", "keep": "mantener", "kitty": "gatito",
        "lion": "león", "leg": "pierna", "lip": "labio", "lap": "regazo", "log": "tronco", "let": "dejar", "lot": "mucho", "low": "bajo", "lid": "tapa",
        "moon": "luna", "man": "hombre", "map": "mapa", "mug": "taza", "mat": "alfombrilla", "mix": "mezcla", "mud": "barro", "mom": "mamá", "me": "yo", "mad": "loco",
        "nest": "nido", "net": "red", "nap": "siesta", "nut": "nuez", "nod": "asentir", "new": "nuevo", "not": "no", "no": "no", "nice": "agradable",
        "owl": "búho", "ox": "buey", "oil": "aceite", "odd": "impar", "off": "apagado", "old": "viejo", "on": "en", "out": "fuera", "oak": "roble",
        "pig": "cerdo", "pen": "bolígrafo", "pot": "olla", "pan": "sartén", "pet": "mascota", "pin": "alfiler", "pop": "pop", "pit": "foso", "pat": "palmadita",
        "queen": "reina", "quilt": "colcha", "quiz": "cuestionario", "quick": "rápido", "quit": "dejar", "quack": "cuac", "quest": "búsqueda",
        "rat": "rata", "rug": "alfombra", "run": "correr", "red": "rojo", "row": "fila", "rip": "rasgar", "rob": "robar", "ram": "carnero", "rod": "vara",
        "sun": "sol", "sit": "sentarse", "sip": "sorbo", "sad": "triste", "sow": "sembrar", "set": "conjunto", "saw": "sierra", "sea": "mar", "six": "seis",
        "top": "arriba", "tap": "grifo", "tin": "estaño", "toy": "juguete", "tip": "consejo", "tag": "etiqueta", "tub": "bañera", "tan": "bronceado", "ten": "diez",
        "umbrella": "paraguas", "up": "arriba", "use": "usar", "us": "nosotros", "urn": "urna", "ugly": "feo", "unit": "unidad",
        "van": "furgoneta", "vet": "veterinario", "vase": "jarrón", "vat": "cuba", "vie": "competir", "via": "vía", "vest": "chaleco", "vivid": "vívido",
        "wet": "mojado", "win": "ganar", "wig": "peluca", "wax": "cera", "way": "camino", "wow": "guau", "web": "web", "was": "era", "will": "voluntad",
        "x-ray": "rayos-x", "xylophone": "xilófono", "xenon": "xenón",
        "yak": "yak", "yes": "sí", "yarn": "hilo", "yell": "gritar", "yet": "aún", "yum": "rico", "you": "tú", "young": "joven",
        "zebra": "cebra", "zip": "cerniera", "zap": "golpear", "zig": "zigzag", "zoo": "zoo", "zen": "zen", "zero": "cero", "zone": "zona"
    ]
    
    let italianTranslations: [String: String] = [
        "apple": "mela", "ant": "formica", "air": "aria", "arm": "braccio", "axe": "ascia", "all": "tutti", "ask": "chiedere", "and": "e", "add": "aggiungere",
        "ball": "palla", "bat": "pipistrello", "bag": "borsa", "bed": "letto", "bear": "orso", "bug": "insetto", "bun": "panino", "bus": "autobus", "big": "grande", "bit": "pezzo",
        "cat": "gatto", "car": "auto", "cow": "mucca", "cup": "tazza", "cap": "cappello", "can": "potere", "cut": "tagliare", "cry": "piangere", "corn": "mais",
        "dog": "cane", "duck": "anatra", "dot": "punto", "dig": "scavare", "doll": "bambola", "dip": "immergere", "day": "giorno", "den": "tana", "dam": "diga",
        "egg": "uovo", "ear": "orecchio", "eat": "mangiare", "end": "fine", "eye": "occhio", "elf": "elfo", "eel": "anguilla", "edge": "bordo", "easy": "facile",
        "fish": "pesce", "fan": "ventilatore", "fog": "nebbia", "fat": "grasso", "fit": "adattare", "fig": "fico", "fun": "divertimento", "far": "lontano", "fox": "volpe",
        "goat": "capra", "gum": "gomma", "gap": "divario", "got": "ottenuto", "gun": "pistola", "gas": "gas", "gut": "intestino", "gig": "concerto", "go": "andare",
        "hat": "cappello", "hen": "gallina", "hop": "salto", "hit": "colpire", "hug": "abbraccio", "hot": "caldo", "hip": "anca", "hum": "canticchiare", "hut": "capanna",
        "ice": "ghiaccio", "ink": "inchiostro", "igloo": "igloo", "ill": "malato", "inn": "locanda", "it": "esso", "is": "è", "if": "se", "in": "in",
        "jam": "marmellata", "jug": "brocca", "jet": "jet", "job": "lavoro", "jog": "jogging", "jaw": "mascella", "joy": "gioia", "jump": "saltare", "jot": "annotare",
        "kite": "aquilone", "key": "chiave", "kid": "bambino", "kit": "kit", "king": "re", "kick": "calcio", "kind": "gentile", "keep": "tenere", "kitty": "gattino",
        "lion": "leone", "leg": "gamba", "lip": "labbro", "lap": "giro", "log": "tronco", "let": "lasciare", "lot": "molto", "low": "basso", "lid": "coperchio",
        "moon": "luna", "man": "uomo", "map": "mappa", "mug": "tazza", "mat": "tappetino", "mix": "miscela", "mud": "fango", "mom": "mamma", "me": "me", "mad": "pazzo",
        "nest": "nido", "net": "rete", "nap": "pisolino", "nut": "noce", "nod": "cenno", "new": "nuovo", "not": "non", "no": "no", "nice": "bello",
        "owl": "gufo", "ox": "bue", "oil": "olio", "odd": "dispari", "off": "spento", "old": "vecchio", "on": "su", "out": "fuori", "oak": "quercia",
        "pig": "maiale", "pen": "penna", "pot": "pentola", "pan": "padella", "pet": "animale", "pin": "spillo", "pop": "pop", "pit": "fossa", "pat": "carezza",
        "queen": "regina", "quilt": "trapunta", "quiz": "quiz", "quick": "veloce", "quit": "uscire", "quack": "qua qua", "quest": "ricerca",
        "rat": "topo", "rug": "tappeto", "run": "correre", "red": "rosso", "row": "fila", "rip": "strappare", "rob": "rubare", "ram": "ariete", "rod": "asta",
        "sun": "sole", "sit": "sedersi", "sip": "sorseggiare", "sad": "triste", "sow": "seminare", "set": "set", "saw": "sega", "sea": "mare", "six": "sei",
        "top": "cima", "tap": "rubinetto", "tin": "latta", "toy": "giocattolo", "tip": "consiglio", "tag": "etichetta", "tub": "vasca", "tan": "abbronzatura", "ten": "dieci",
        "umbrella": "ombrello", "up": "su", "use": "usare", "us": "noi", "urn": "urna", "ugly": "brutto", "unit": "unità",
        "van": "furgone", "vet": "veterinario", "vase": "vaso", "vat": "tino", "vie": "competere", "via": "via", "vest": "gilet", "vivid": "vivido",
        "wet": "bagnato", "win": "vincere", "wig": "parrucca", "wax": "cera", "way": "via", "wow": "wow", "web": "web", "was": "era", "will": "volontà",
        "x-ray": "raggi x", "xylophone": "xilofono", "xenon": "xenon",
        "yak": "yak", "yes": "sì", "yarn": "filato", "yell": "urlare", "yet": "ancora", "yum": "yum", "you": "tu", "young": "giovane",
        "zebra": "zebra", "zip": "cerniera", "zap": "colpire", "zig": "zigzag", "zoo": "zoo", "zen": "zen", "zero": "zero", "zone": "zona"
    ]
    
    let japaneseTranslations: [String: String] = [
        "apple": "りんご", "ant": "あり", "air": "くうき", "arm": "うで", "axe": "おの", "all": "すべて", "ask": "たずねる", "and": "そして", "add": "くわえる",
        "ball": "ボール", "bat": "こうもり", "bag": "かばん", "bed": "ベッド", "bear": "くま", "bug": "むし", "bun": "パン", "bus": "バス", "big": "おおきい", "bit": "かけら",
        "cat": "ねこ", "car": "くるま", "cow": "うし", "cup": "カップ", "cap": "ぼうし", "can": "できる", "cut": "きる", "cry": "なく", "corn": "とうもろこし",
        "dog": "いぬ", "duck": "あひる", "dot": "てん", "dig": "ほる", "doll": "にんぎょう", "dip": "つける", "day": "ひ", "den": "あな", "dam": "ダム",
        "egg": "たまご", "ear": "みみ", "eat": "たべる", "end": "おわり", "eye": "め", "elf": "エルフ", "eel": "うなぎ", "edge": "はし", "easy": "かんたん",
        "fish": "さかな", "fan": "せんぷうき", "fog": "きり", "fat": "ふとい", "fit": "あう", "fig": "いちじく", "fun": "たのしい", "far": "とおい", "fox": "きつね",
        "goat": "やぎ", "gum": "ガム", "gap": "すきま", "got": "えた", "gun": "ピストル", "gas": "ガス", "gut": "はらわた", "gig": "ライブ", "go": "いく",
        "hat": "ぼうし", "hen": "めんどり", "hop": "はねる", "hit": "たたく", "hug": "だきしめる", "hot": "あつい", "hip": "こし", "hum": "ハミング", "hut": "こや",
        "ice": "こおり", "ink": "インク", "igloo": "かまくら", "ill": "びょうき", "inn": "やど", "it": "それ", "is": "です", "if": "もし", "in": "なかに",
        "jam": "ジャム", "jug": "かめ", "jet": "ジェット", "job": "しごと", "jog": "ジョギング", "jaw": "あご", "joy": "よろこび", "jump": "ジャンプ", "jot": "メモ",
        "kite": "たこ", "key": "かぎ", "kid": "こども", "kit": "キット", "king": "おう", "kick": "ける", "kind": "しんせつ", "keep": "たもつ", "kitty": "こねこ",
        "lion": "ライオン", "leg": "あし", "lip": "くちびる", "lap": "ひざ", "log": "まるた", "let": "させる", "lot": "たくさん", "low": "ひくい", "lid": "ふた",
        "moon": "つき", "man": "おとこ", "map": "ちず", "mug": "マグカップ", "mat": "マット", "mix": "まぜる", "mud": "どろ", "mom": "かあさん", "me": "わたし", "mad": "おこった",
        "nest": "す", "net": "あみ", "nap": "うたたね", "nut": "ナッツ", "nod": "うなずく", "new": "あたらしい", "not": "ない", "no": "いいえ", "nice": "すてき",
        "owl": "ふくろう", "ox": "うし", "oil": "あぶら", "odd": "きすう", "off": "オフ", "old": "ふるい", "on": "オン", "out": "そと", "oak": "かしの木",
        "pig": "ぶた", "pen": "ペン", "pot": "なべ", "pan": "フライパン", "pet": "ペット", "pin": "ピン", "pop": "ポップ", "pit": "あな", "pat": "ポン",
        "queen": "じょおう", "quilt": "キルト", "quiz": "クイズ", "quick": "はやい", "quit": "やめる", "quack": "ガーガー", "quest": "たんきゅう",
        "rat": "ねずみ", "rug": "じゅうたん", "run": "はしる", "red": "あか", "row": "れつ", "rip": "やぶる", "rob": "うばう", "ram": "おひつじ", "rod": "さお",
        "sun": "たいよう", "sit": "すわる", "sip": "すする", "sad": "かなしい", "sow": "まく", "set": "セット", "saw": "のこぎり", "sea": "うみ", "six": "ろく",
        "top": "てっぺん", "tap": "たたく", "tin": "すず", "toy": "おもちゃ", "tip": "ヒント", "tag": "タグ", "tub": "たらい", "tan": "ひやけ", "ten": "じゅう",
        "umbrella": "かさ", "up": "うえ", "use": "つかう", "us": "わたしたち", "urn": "つぼ", "ugly": "みにくい", "unit": "たんい",
        "van": "バン", "vet": "じゅうい", "vase": "かびん", "vat": "おけ", "vie": "きそう", "via": "けいゆ", "vest": "ベスト", "vivid": "あざやか",
        "wet": "ぬれた", "win": "かつ", "wig": "かつら", "wax": "ろう", "way": "みち", "wow": "わあ", "web": "ウェブ", "was": "だった", "will": "つもり",
        "x-ray": "レントゲン", "xylophone": "木琴", "xenon": "キセノン",
        "yak": "ヤク", "yes": "はい", "yarn": "毛糸", "yell": "さけぶ", "yet": "まだ", "yum": "おいしい", "you": "あなた", "young": "わかい",
        "zebra": "しまうま", "zip": "ジッパー", "zap": "ピシッ", "zig": "ジグザグ", "zoo": "どうぶつえん", "zen": "禅", "zero": "ゼロ", "zone": "エリア"
    ]
    
    let chineseTranslations: [String: String] = [
        "apple": "苹果", "ant": "蚂蚁", "air": "空气", "arm": "手臂", "axe": "斧头", "all": "全部", "ask": "问", "and": "和", "add": "添加",
        "ball": "球", "bat": "蝙蝠", "bag": "包", "bed": "床", "bear": "熊", "bug": "虫子", "bun": "面包", "bus": "公交车", "big": "大", "bit": "一点",
        "cat": "猫", "car": "车", "cow": "牛", "cup": "杯子", "cap": "帽子", "can": "能", "cut": "切", "cry": "哭", "corn": "玉米",
        "dog": "狗", "duck": "鸭子", "dot": "点", "dig": "挖", "doll": "娃娃", "dip": "蘸", "day": "天", "den": "洞穴", "dam": "水坝",
        "egg": "蛋", "ear": "耳朵", "eat": "吃", "end": "结束", "eye": "眼睛", "elf": "精灵", "eel": "鳗鱼", "edge": "边缘", "easy": "容易",
        "fish": "鱼", "fan": "风扇", "fog": "雾", "fat": "胖", "fit": "适合", "fig": "无花果", "fun": "有趣", "far": "远", "fox": "狐狸",
        "goat": "山羊", "gum": "口香糖", "gap": "间隙", "got": "得到", "gun": "枪", "gas": "气体", "gut": "肠子", "gig": "演出", "go": "去",
        "hat": "帽子", "hen": "母鸡", "hop": "跳", "hit": "打", "hug": "拥抱", "hot": "热", "hip": "臀部", "hum": "哼唱", "hut": "小屋",
        "ice": "冰", "ink": "墨水", "igloo": "冰屋", "ill": "生病", "inn": "旅馆", "it": "它", "is": "是", "if": "如果", "in": "在",
        "jam": "果酱", "jug": "壶", "jet": "喷气机", "job": "工作", "jog": "慢跑", "jaw": "下巴", "joy": "喜悦", "jump": "跳", "jot": "记下",
        "kite": "风筝", "key": "钥匙", "kid": "孩子", "kit": "工具包", "king": "国王", "kick": "踢", "kind": "友好", "keep": "保持", "kitty": "小猫",
        "lion": "狮子", "leg": "腿", "lip": "嘴唇", "lap": "大腿", "log": "原木", "let": "让", "lot": "很多", "low": "低", "lid": "盖子",
        "moon": "月亮", "man": "男人", "map": "地图", "mug": "杯子", "mat": "垫子", "mix": "混合", "mud": "泥", "mom": "妈妈", "me": "我", "mad": "生气",
        "nest": "巢", "net": "网", "nap": "小睡", "nut": "坚果", "nod": "点头", "new": "新", "not": "不", "no": "不", "nice": "好",
        "owl": "猫头鹰", "ox": "牛", "oil": "油", "odd": "奇数", "off": "关", "old": "老", "on": "开", "out": "出", "oak": "橡树",
        "pig": "猪", "pen": "笔", "pot": "锅", "pan": "平底锅", "pet": "宠物", "pin": "别针", "pop": "流行", "pit": "坑", "pat": "拍",
        "queen": "女王", "quilt": "被子", "quiz": "测验", "quick": "快", "quit": "退出", "quack": "嘎嘎", "quest": "寻求",
        "rat": "老鼠", "rug": "地毯", "run": "跑", "red": "红色", "row": "行", "rip": "撕", "rob": "抢", "ram": "公羊", "rod": "杆",
        "sun": "太阳", "sit": "坐", "sip": "啜饮", "sad": "悲伤", "sow": "播种", "set": "套", "saw": "锯", "sea": "海", "six": "六",
        "top": "顶部", "tap": "水龙头", "tin": "锡", "toy": "玩具", "tip": "提示", "tag": "标签", "tub": "浴缸", "tan": "晒黑", "ten": "十",
        "umbrella": "伞", "up": "上", "use": "使用", "us": "我们", "urn": "骨灰盒", "ugly": "丑", "unit": "单位",
        "van": "厢式货车", "vet": "兽医", "vase": "花瓶", "vat": "大桶", "vie": "竞争", "via": "通过", "vest": "背心", "vivid": "生动",
        "wet": "湿", "win": "赢", "wig": "假发", "wax": "蜡", "way": "路", "wow": "哇", "web": "网络", "was": "是", "will": "将",
        "x-ray": "X光", "xylophone": "木琴", "xenon": "氙",
        "yak": "牦牛", "yes": "是", "yarn": "纱线", "yell": "叫喊", "yet": "尚", "yum": "好吃", "you": "你", "young": "年轻",
        "zebra": "斑马", "zip": "拉链", "zap": "啪", "zig": "锯齿", "zoo": "动物园", "zen": "禅", "zero": "零", "zone": "区域"
    ]
    
    private var wordSetType: WordSetType = .randomShortWords
    private let customWordSetsManager = CustomWordSetsManager.shared
    
    private let synthesizer = NSSpeechSynthesizer()
    private let synth = AVSpeechSynthesizer()
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
        
        if wordSetType == .mainWords {
            let customMap = customWordSetsManager.getWordMap()
            if let words = customMap[key], let randomWord = words.randomElement() {
                debugPrint("getWord from main words set ------- \(key) -- \(randomWord)")
                return randomWord
            }
            return key
        }
        
        // Default behavior using simpleWordsMap
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
        if wordSetType == .mainWords {
            if let translation = customWordSetsManager.getTranslation(for: word) {
                return translation
            }
        }
        
        switch language {
        case .french:
            return frenchTranslations[word.lowercased()]
        case .russian: 
            return russianTranslations[word.lowercased()]
        case .german:
            return germanTranslations[word.lowercased()]
        case .spanish:
            return spanishTranslations[word.lowercased()]
        case .italian:
            return italianTranslations[word.lowercased()]
        case .japanese:
            return japaneseTranslations[word.lowercased()]
        case .chinese:
            return chineseTranslations[word.lowercased()]
        case .none:
            return nil
        }
    }
    
    func setWordSetType(_ type: WordSetType) {
        wordSetType = type
    }
}
