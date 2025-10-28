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

        let languageCode = language ?? Locale.preferredLanguages[0]

        // Cache voices to ensure consistent voice selection across calls
        if let cachedVoice = voiceCache[languageCode] {
            utterance.voice = cachedVoice
        } else {
            // https://stackoverflow.com/questions/37512621/avspeechsynthesizer-change-voice
            let allVoices = AVSpeechSynthesisVoice.speechVoices().filter { voice in
                guard languageCode == voice.language else { return false}
                return true
            }
            let selectedVoice = allVoices.first {voice in voice.identifier.contains("siri") } ?? allVoices.first
            if let selectedVoice = selectedVoice {
                voiceCache[languageCode] = selectedVoice
            }
            utterance.voice = selectedVoice
        }

        return utterance
    }
}

