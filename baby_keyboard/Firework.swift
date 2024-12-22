//
//  Firework.swift
//  baby_keyboard
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import SwiftUI
import Combine
import AVFoundation

//class FireworkWindow: NSWindow {
//    init() {
//        let screen = NSScreen.main!
//        super.init(contentRect: screen.frame,
//                  styleMask: .borderless,
//                  backing: .buffered,
//                  defer: false)
//        
//        backgroundColor = .clear
//        isOpaque = false
//        level = .floating
//        ignoresMouseEvents = true
//        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
//    }
//}

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

struct FireworkView: View {
    @State private var initialized = false
    @State private var windowSize: CGSize = .zero
    @StateObject private var fireworkController = FireworkController()
    @EnvironmentObject var eventHandler: EventHandler
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                
                ForEach(fireworkController.particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                windowSize = geometry.size
            }
            .onChange(of: eventHandler.lastKeyString) { _, newVal in
//                guard let letter = eventHandler.lastKeyString.first else { return }
//                if !letter.isLetter { return }
//                
//                fireworkController.createFirework(
//                    at: CGPoint(
//                        x: Int.random(in: 0...Int(windowSize.width)),
//                        y: Int.random(in: 0...Int(windowSize.height))
//                    )
//                )
            }.onReceive(eventHandler.$lastKeyString) { _ in
                if !initialized {
                    self.initialized = true
                    return
                }
                fireworkController.createFirework(
                    at: CGPoint(
                        x: Int.random(in: 0...Int(windowSize.width)),
                        y: Int.random(in: 0...Int(windowSize.height))
                    )
                )
            }
        }
        .fullscreenTransparentWindow()
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double = 1.0
}

class FireworkController: ObservableObject {
    @Published var particles: [Particle] = []
    @Published var shouldTrigger = false
    
    func createFirework(at position: CGPoint) {
        let particleCount = Int.random(in: 50...100)
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        
        for _ in 0..<particleCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = Double.random(in: 1...10)
            let velocity = CGPoint(
                x: cos(angle) * speed,
                y: sin(angle) * speed
            )
            
            let particle = Particle(
                position: position,
                velocity: velocity,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 2...6)
            )
            particles.append(particle)
        }
        
        // Start animation
        animate()
    }
    
    private func animate() {
        playFireworkSound()
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            var shouldContinue = false
            
            self.particles = self.particles.compactMap { particle in
                var newParticle = particle
                
                // Update position
                newParticle.position.x += particle.velocity.x
                newParticle.position.y += particle.velocity.y
                
                // Apply gravity
                newParticle.velocity.y += 0.3
                
                // Fade out
                newParticle.opacity -= 0.02
                
                if newParticle.opacity > 0 {
                    shouldContinue = true
                    return newParticle
                }
                return nil
            }
            
            if !shouldContinue {
                timer.invalidate()
            }
        }
    }
    
    func playFireworkSound() {
        // let launchDelay = Double.random(in: 0.5...1.5)
        // let explosionDelay = launchDelay + Double.random(in: 0.5...1.5)
        // let volume = Float.random(in: 0.5...1.0)
        // let pitch = Float.random(in: 0.8...1.2)

        // SoundManager.shared.audioPlayer?.volume = volume
        // SoundManager.shared.audioPlayer?.rate = pitch

        // DispatchQueue.main.async as {
            //SoundManager.shared.playSound(soundName: "cannon1", soundExtension: "wav")
            // SoundManager.shared.audioPlayer?.volume = volume
            // SoundManager.shared.audioPlayer?.rate = pitch
            guard let nsSound = NSSound(named: "confetti-cannon") else { return }
            
            (nsSound.copy() as! NSSound).play()
        // }
       
        
    }
}
