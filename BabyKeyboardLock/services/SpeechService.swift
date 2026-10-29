//
//  SpeechService.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import AVFoundation
import Foundation

class SpeechService {
    private let synthesizer: SpeechSynthesizing
    private var voiceCache: [String: AVSpeechSynthesisVoice] = [:]

    init(synthesizer: SpeechSynthesizing = AVSpeechSynthesizer()) {
        self.synthesizer = synthesizer
    }

    func speak(_ text: String, language: String? = nil) {
        DispatchQueue.global(qos: .background).async {
            // Stop any ongoing speech to prevent queue buildup
            if self.synthesizer.isSpeaking {
                _ = self.synthesizer.stopSpeaking(at: .immediate)
            }
            self.synthesizer.speak(self.createUtterance(for: text, language: language))
        }
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking {
            _ = synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func createUtterance(for str: String, language: String? = nil) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: str)

        let languageCode = language ?? Locale.preferredLanguages.first ?? "en-US"

        // Cache voices to ensure consistent voice selection across calls
        if let cachedVoice = voiceCache[languageCode] {
            utterance.voice = cachedVoice
        } else {
            let allVoices = AVSpeechSynthesisVoice.speechVoices()
            var matchingVoices = allVoices.filter { $0.language == languageCode }

            // Fallback to language prefix (e.g. "en" for "en-FI") if exact locale tag not found
            if matchingVoices.isEmpty {
                let languagePrefix = languageCode.prefix(2).lowercased()
                matchingVoices = allVoices.filter { $0.language.lowercased().hasPrefix(languagePrefix) }
            }

            let selectedVoice = matchingVoices.first { $0.identifier.contains("siri") }
                ?? matchingVoices.first
                ?? AVSpeechSynthesisVoice(language: languageCode)
                ?? AVSpeechSynthesisVoice(language: "en-US")

            if let selectedVoice = selectedVoice {
                voiceCache[languageCode] = selectedVoice
            }
            utterance.voice = selectedVoice
        }

        return utterance
    }
}
