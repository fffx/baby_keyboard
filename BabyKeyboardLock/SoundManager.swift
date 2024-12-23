//
//  SoundManager.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 21.12.2024.
//

import AVFoundation

class SoundManager: NSObject, AVAudioPlayerDelegate {
    static let shared = SoundManager()
    var audioPlayer: AVAudioPlayer?

    func playSound(soundName: String, soundExtension: String) {
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: soundExtension) else {
            print("Could not find sound file.")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.delegate = self // Important for completion handling
            audioPlayer?.play()
        } catch {
            print("Could not create audio player: \(error)")
        }
    }

    // AVAudioPlayerDelegate method (optional)
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            print("Sound finished playing.")
        } else {
            print("Sound playback failed.")
        }
    }
}
