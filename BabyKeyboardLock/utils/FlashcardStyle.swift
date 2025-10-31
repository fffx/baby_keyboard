import Foundation
import SwiftUI

enum FlashcardStyle: String, CaseIterable {
    case none
    case crayon
    case doodle
    case pencil
    case simple
    case watercolor
    case mosaic
    case elvish
    case random

    var title: String {
        switch self {
        case .none: return "No Image"
        case .random: return "Random"
        default: return rawValue.capitalized
        }
    }
}

extension UserDefaults {
    var flashcardStyle: FlashcardStyle {
        get {
            if let rawValue = string(forKey: "flashcardStyle"),
               let style = FlashcardStyle(rawValue: rawValue) {
                return style
            }
            return .none
        }
        set {
            set(newValue.rawValue, forKey: "flashcardStyle")
        }
    }
}

extension RandomWord {
    func flashcardImage(style: FlashcardStyle) -> Image? {
        // Return nil for 'none' style or if word is empty
        guard style != .none, !english.isEmpty else { return nil }

        // Handle random style by picking a random style from available styles
        let actualStyle: FlashcardStyle = {
            if style == .random {
                let availableStyles = FlashcardStyle.allCases.filter { $0 != .none && $0 != .random }
                return availableStyles.randomElement() ?? .simple
            }
            return style
        }()

        // Handle spaces in filenames and add style prefix
        let sanitizedEnglish = english.lowercased().replacingOccurrences(of: " ", with: "_")
        let filename = "\(actualStyle.rawValue)_\(sanitizedEnglish).png"

        // For debugging
        print("Looking for image: \(filename)")

        // Return nil if image doesn't exist - no error, just no image
        if let nsImage = NSImage(named: filename) {
            return Image(nsImage: nsImage)
        }
        return nil
    }
} 
