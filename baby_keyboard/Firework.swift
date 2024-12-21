//
//  Firework.swift
//  baby_keyboard
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import SwiftUI
import Combine

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


struct FireworkView: View {
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
        }
        .onReceive(eventHandler.$lastKeyString){ _ in
            fireworkController.createFirework(
                at: CGPoint(
                    x: Int.random(in: 0...800),
                    y: Int.random(in: 0...800)
                )
            )
        }
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
            let speed = Double.random(in: 5...15)
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
}
