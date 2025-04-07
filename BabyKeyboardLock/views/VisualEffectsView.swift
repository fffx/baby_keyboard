//
//  VisualEffectsView.swift
//  BabyKeyboardLock
//
//  Created on 07.04.2024.
//

import SwiftUI
import Combine

// A view that manages the various visual effects when keys are pressed
struct VisualEffectsView: View {
    @ObservedObject var eventHandler: EventHandler = EventHandler.shared
    @State private var initialized = false
    @State private var effectPosition: CGPoint = .zero
    @State private var windowSize: CGSize = .zero
    
    // Effect states
    @State private var showBubbles = false
    @State private var bubbleCount = 0
    @State private var showStars = false
    @State private var starCount = 0
    @State private var showAnimals = false
    @State private var animalType = 0
    @State private var showRainbowTrail = false
    @State private var rainbowPoints: [CGPoint] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Bubbles Effect
                if eventHandler.selectedLockEffect == .bubbles {
                    BubblesEffectView(
                        isActive: $showBubbles,
                        count: $bubbleCount,
                        position: $effectPosition
                    )
                }
                
                // Stars Effect
                if eventHandler.selectedLockEffect == .stars {
                    StarsEffectView(
                        isActive: $showStars,
                        count: $starCount,
                        position: $effectPosition
                    )
                }
                
                // Animal Effect
                if eventHandler.selectedLockEffect == .animals {
                    AnimalsEffectView(
                        isActive: $showAnimals,
                        animalType: $animalType,
                        position: $effectPosition
                    )
                }
                
                // Rainbow Trail Effect
                if eventHandler.selectedLockEffect == .rainbowTrail {
                    RainbowTrailEffectView(
                        isActive: $showRainbowTrail,
                        points: $rainbowPoints
                    )
                }
            }
            .onAppear {
                windowSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
                debugPrint("VisualEffectsView -------- windowSize: \(windowSize)")
            }
            .onChange(of: eventHandler.isLocked) { newVal in
                if !newVal {
                    initialized = false
                    rainbowPoints = []
                }
            }
            .onReceive(eventHandler.$lastKeyString) { _ in
                if !initialized {
                    self.initialized = true
                    return
                }
                if(!eventHandler.isLocked) { return }
                
                // Only process for specific visual effects
                let effect = eventHandler.selectedLockEffect
                if effect != .bubbles && effect != .stars && effect != .animals && effect != .rainbowTrail {
                    return
                }
                
                guard let letter = eventHandler.lastKeyString.first, letter.isLetter || letter.isNumber else { return }
                
                // Generate random position for the effect
                let randomX = CGFloat.random(in: 0...geometry.size.width)
                let randomY = CGFloat.random(in: 0...geometry.size.height)
                effectPosition = CGPoint(x: randomX, y: randomY)
                
                // Trigger the appropriate visual effect
                switch effect {
                case .bubbles:
                    bubbleCount += 1
                    showBubbles = true
                case .stars:
                    starCount += 1
                    showStars = true
                case .animals:
                    animalType = Int.random(in: 0...5) // Different animal types
                    showAnimals = true
                case .rainbowTrail:
                    rainbowPoints.append(effectPosition)
                    if rainbowPoints.count > 20 {
                        rainbowPoints.removeFirst()
                    }
                    showRainbowTrail = true
                default:
                    break
                }
            }
        }
        .fullscreenTransparentWindow()
    }
}

// MARK: - Effect View Components

struct BubblesEffectView: View {
    @Binding var isActive: Bool
    @Binding var count: Int
    @Binding var position: CGPoint
    
    var body: some View {
        ZStack {
            ForEach(0..<15, id: \.self) { index in
                Bubble(count: count, index: index, position: position)
            }
        }
    }
}

struct Bubble: View {
    let count: Int
    let index: Int
    let position: CGPoint
    
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.4),
                        Color.blue.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: CGFloat.random(in: 10...40), height: CGFloat.random(in: 10...40))
            .position(x: position.x, y: position.y)
            .offset(offset)
            .scaleEffect(scale)
            .opacity(opacity)
            .onChange(of: count) { _ in
                withAnimation(.easeOut(duration: 3.0)) {
                    let randomAngle = Double.random(in: 0...(2 * .pi))
                    let randomDistance = CGFloat.random(in: 50...200)
                    offset = CGSize(
                        width: cos(randomAngle) * randomDistance,
                        height: sin(randomAngle) * randomDistance - randomDistance // Always float up
                    )
                    scale = CGFloat.random(in: 0.5...1.5)
                    opacity = 1
                }
                
                // Fade out and reset for reuse
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    offset = .zero
                    scale = 0
                }
            }
    }
}

struct StarsEffectView: View {
    @Binding var isActive: Bool
    @Binding var count: Int
    @Binding var position: CGPoint
    
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Star(count: count, index: index, position: position)
            }
        }
    }
}

struct Star: View {
    let count: Int
    let index: Int
    let position: CGPoint
    
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "star.fill")
            .foregroundColor(Color.yellow)
            .frame(width: 30, height: 30)
            .position(x: position.x, y: position.y)
            .offset(offset)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onChange(of: count) { _ in
                let delay = Double(index) * 0.05
                
                withAnimation(Animation.easeOut(duration: 2.0).delay(delay)) {
                    let randomAngle = Double.random(in: 0...(2 * .pi))
                    let randomDistance = CGFloat.random(in: 30...150)
                    offset = CGSize(
                        width: cos(randomAngle) * randomDistance,
                        height: sin(randomAngle) * randomDistance
                    )
                    scale = CGFloat.random(in: 0.3...1.0)
                    opacity = 1
                    rotation = Double.random(in: 0...360)
                }
                
                // Twinkle animation
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever().delay(delay)) {
                    scale *= CGFloat.random(in: 0.8...1.2)
                }
                
                // Fade out and reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + delay) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 + delay) {
                    offset = .zero
                    scale = 0
                    rotation = 0
                }
            }
    }
}

struct AnimalsEffectView: View {
    @Binding var isActive: Bool
    @Binding var animalType: Int
    @Binding var position: CGPoint
    
    var body: some View {
        ZStack {
            AnimalImage(animalType: animalType, position: position)
        }
    }
}

struct AnimalImage: View {
    let animalType: Int
    let position: CGPoint
    
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var bounce: CGFloat = 0
    
    var animalEmoji: String {
        // Different animal emojis
        let animals = ["🐶", "🐱", "🐰", "🐼", "🦊", "🐵"]
        return animals[animalType % animals.count]
    }
    
    var body: some View {
        Text(animalEmoji)
            .font(.system(size: 60))
            .position(x: position.x, y: position.y)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: bounce)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
                
                // Bounce animation
                withAnimation(Animation.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
                    bounce = -20
                }
                
                // Fade out and reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 0
                        scale = 0.5
                    }
                }
            }
    }
}

struct RainbowTrailEffectView: View {
    @Binding var isActive: Bool
    @Binding var points: [CGPoint]
    
    var body: some View {
        ZStack {
            // Draw a path through all points
            if points.count > 1 {
                RainbowPath(points: points)
            }
        }
    }
}

struct RainbowPath: View {
    let points: [CGPoint]
    
    var body: some View {
        Path { path in
            guard let firstPoint = points.first else { return }
            
            path.move(to: firstPoint)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
        )
        .opacity(0.7)
    }
} 