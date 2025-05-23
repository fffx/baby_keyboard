//
//  Firework.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import SwiftUI
import Combine
import AVFoundation
import ConfettiSwiftUI

struct FullscreenTransparentWindow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(FullscreenTransparentWindowBackground())
    }
}

private struct FullscreenTransparentWindowBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            
            window.isOpaque = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = true
            window.level = .screenSaver
            window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
            window.setFrame(.init(origin: .zero, size: NSScreen.main!.frame.size), display: true)
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func fullscreenTransparentWindow() -> some View {
        modifier(FullscreenTransparentWindow())
    }
}

struct AnimationView: View {
    @State private var confettiStates: [Int: CGPoint] = [:] // Maps counter to position
    @State private var initialized = false
    
    @State private var soundPool: [NSSound] = []
    @State private var sound: NSSound? = NSSound(named: "confetti-cannon")
    @State private var windowSize: CGSize = .zero
    @ObservedObject var eventHandler: EventHandler = EventHandler.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(confettiStates.keys), id: \.self) { counter in
                    ConfettiContainer(counter: counter, position: confettiStates[counter] ?? .zero)
                }
            }
            .padding()
            .presentedWindowStyle(.hiddenTitleBar)
            .onAppear {
                windowSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
                debugPrint("\(AnimationWindowID)-------- windowSize: \(windowSize)")
            }
            .onChange(of: eventHandler.isLocked) { oldVal, newVal in
                if !newVal {
                    initialized = false
                }
            }
            .onReceive(eventHandler.$lastKeyString) { _ in
                if !initialized {
                    self.initialized = true
                    return
                }
                if(!eventHandler.isLocked) { return }
                
                // ##### Confetti handler
                if eventHandler.selectedLockEffect != .confettiCannon { return }
                
                guard let letter = eventHandler.lastKeyString.first, letter.isLetter || letter.isNumber else { return }
                
                let randomX = CGFloat.random(in: 0...geometry.size.width)
                let randomY = CGFloat.random(in: 0...geometry.size.height)
                
                // Create new confetti with unique counter
                let newCounter = Int.random(in: 0...Int.max)
                confettiStates[newCounter] = CGPoint(x: randomX, y: randomY)
                
                // Remove this confetti state after animation is done
                DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + eventHandler.confettiFadeTime) {
                    DispatchQueue.main.async {
                        confettiStates.removeValue(forKey: newCounter)
                    }
                }
                
                playSound()
            }
        }
        .fullscreenTransparentWindow()
    }
    
    private func playSound() {
        if sound != nil && soundPool.isEmpty {
            soundPool = Array(repeating: sound!, count: 5).map { $0.copy() as! NSSound }
        }
        guard let availableSound = soundPool.first(where: { !$0.isPlaying }) else { return }
        availableSound.play()
    }
}

// Separate view for each confetti animation
struct ConfettiContainer: View {
    let counter: Int
    let position: CGPoint
    @State private var triggerConfetti = 0
    
    var body: some View {
        Color.clear
            .confettiCannon(
                counter: $triggerConfetti,
                num: Int.random(in: 50...100),
                confettiSize: 10,
                rainHeight: 600,
                radius: 400,
                repetitions: 0
            )
            .position(position)
            .onAppear {
                triggerConfetti += 1
            }
    }
}
