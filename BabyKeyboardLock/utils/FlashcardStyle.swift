import Foundation
import SwiftUI

enum FlashcardStyle: String, CaseIterable {
    case none
    case crayon
    case doodle
    case pencil
    case simple
    
    var title: String {
        switch self {
        case .none: return "No Image"
        default: return rawValue.capitalized
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "xmark.circle"
        case .crayon: return "pencil.and.outline"
        case .doodle: return "scribble"
        case .pencil: return "pencil.line"
        case .simple: return "square.on.circle"
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
        
        // Handle spaces in filenames and add style prefix
        let sanitizedEnglish = english.lowercased().replacingOccurrences(of: " ", with: "_")
        let filename = "\(style.rawValue)_\(sanitizedEnglish).png"
        
        // For debugging
        print("Looking for image: \(filename)")
        
        // Return nil if image doesn't exist - no error, just no image
        if let nsImage = NSImage(named: filename) {
            return Image(nsImage: nsImage)
        }
        return nil
    }
} 