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

        // Check if this is a color word and generate color square on-the-fly
        if let colorImage = generateColorImage(for: english.lowercased()) {
            return colorImage
        }

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

    private func generateColorImage(for word: String) -> Image? {
        // Define color mappings
        let colorMap: [String: NSColor] = [
            "red": NSColor(red: 220/255, green: 38/255, blue: 38/255, alpha: 1.0),
            "blue": NSColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 1.0),
            "green": NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1.0),
            "yellow": NSColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 1.0),
            "orange": NSColor(red: 234/255, green: 88/255, blue: 12/255, alpha: 1.0),
            "purple": NSColor(red: 147/255, green: 51/255, blue: 234/255, alpha: 1.0),
            "pink": NSColor(red: 219/255, green: 39/255, blue: 119/255, alpha: 1.0),
            "brown": NSColor(red: 120/255, green: 53/255, blue: 15/255, alpha: 1.0),
            "black": NSColor(red: 0, green: 0, blue: 0, alpha: 1.0),
            "white": NSColor(red: 1, green: 1, blue: 1, alpha: 1.0),
            "gray": NSColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1.0),
            "grey": NSColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1.0), // Alternative spelling
        ]

        guard let color = colorMap[word] else { return nil }

        // Generate a simple colored square
        let size = NSSize(width: 800, height: 800)
        let image = NSImage(size: size)

        image.lockFocus()

        // Fill with color
        color.setFill()
        NSRect(x: 0, y: 0, width: 800, height: 800).fill()

        // Add a subtle border for white to show edges
        if word == "white" {
            let borderColor = NSColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0)
            borderColor.setStroke()
            let borderPath = NSBezierPath(rect: NSRect(x: 10, y: 10, width: 780, height: 780))
            borderPath.lineWidth = 10
            borderPath.stroke()
        }

        image.unlockFocus()

        return Image(nsImage: image)
    }
} 
