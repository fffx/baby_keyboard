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
            window.collectionBehavior = [.fullScreenAuxiliary]
            window.setFrame(.init(origin: .zero, size: NSScreen.main!.frame.size), display: true)
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true

            // Fix lagging shadow by configuring proper backing and compositing
            window.hasShadow = false
            window.isMovableByWindowBackground = false

            // Enable layer backing for better performance
            if let contentView = window.contentView {
                contentView.wantsLayer = true
                contentView.layer?.backgroundColor = NSColor.clear.cgColor
            }
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
    @State private var counter: Int = 0
    @State private var initialized = false
    @State private var buttonPosition: CGPoint = .zero

    @State private var soundPool: [NSSound] = []
    @State private var sound: NSSound? = NSSound(named: "confetti-cannon")
    @State private var windowSize: CGSize = .zero
    @State private var lastCleanupTime: Date = Date()
    @ObservedObject var eventHandler: EventHandler = EventHandler.shared

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Button("") { counter += 1 }
                    .background(Color.clear)
                .buttonStyle(PlainButtonStyle())
                .confettiCannon(
                    counter: $counter,
                    // confettis: [.text("💩")],
                    num: Int.random(in: 15...40),
                    confettiSize: 15,
                    rainHeight: 800,
                    radius: 500
                )
                .position(x: buttonPosition.x, y: buttonPosition.y)
            }
            .padding()
            .presentedWindowStyle(.hiddenTitleBar)
            .onAppear {
                // windowSize = geometry.size
                windowSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
                debugLog("\(AnimationWindowID)-------- windowSize: \(windowSize)")
            }
            .onChange(of: eventHandler.isLocked) { newVal in
                if !newVal {
                    // TODO https://stackoverflow.com/questions/64391947/swiftui-prevent-onreceive-from-firing-on-load
                    initialized = false // avoild confetti on toggle lock
                    cleanupSoundPool() // Clean up when unlocking
                }
            }
            .onReceive(eventHandler.$lastKeyString) { _ in
                debugLog("\(AnimationWindowID)-------- initialized: \(initialized), locked \(eventHandler.isLocked)")
                if !initialized {
                    self.initialized = true
                    return
                }
                if(!eventHandler.isLocked) { return }

                // ##### Confetti handler
                if eventHandler.selectedLockEffect != .confettiConnon { return }

                guard let letter = eventHandler.lastKeyString.first, letter.isLetter || letter.isNumber else { return }

                counter = (counter + 1) % 10
                let randomX = CGFloat.random(in: 0...geometry.size.width)
                let randomY = CGFloat.random(in: 0...geometry.size.height)

                // Update the button's position
                buttonPosition = CGPoint(x: randomX, y: randomY)
                playSound()

                // Periodic cleanup every 5 minutes
                periodicCleanup()
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

    private func cleanupSoundPool() {
        // Stop all sounds and clear the pool
        soundPool.forEach { $0.stop() }
        soundPool.removeAll()
        debugLog("Sound pool cleaned up")
    }

    private func periodicCleanup() {
        let now = Date()
        // Clean up every 5 minutes to prevent memory buildup
        if now.timeIntervalSince(lastCleanupTime) > 300 {
            lastCleanupTime = now
            soundPool.removeAll(where: { !$0.isPlaying })
        }
    }

}
