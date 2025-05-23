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
    @State private var previousEffect: LockEffect = .none
    
    // Effect states
    @State private var showBubbles = false
    @State private var bubbleCount = 0
    @State private var showStars = false
    @State private var starCount = 0
    @State private var showAnimals = false
    @State private var animalType = 0
    @State private var showRainbowTrail = false
    @State private var rainbowPoints: [CGPoint] = []
    @State private var rainbowOpacities: [Double] = []
    
    private func resetAllEffects() {
        // Clear all animation states only if they're not already empty
        let hadContent = !rainbowPoints.isEmpty || !rainbowOpacities.isEmpty
        rainbowPoints = []
        rainbowOpacities = []
        
        if hadContent {
            debugPrint("Resetting all visual effects")
        }
    }
    
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
                        points: $rainbowPoints,
                        opacities: $rainbowOpacities
                    )
                }
            }
            .onAppear {
                windowSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
                debugPrint("VisualEffectsView -------- windowSize: \(windowSize)")
                previousEffect = eventHandler.selectedLockEffect
            }
            .onChange(of: eventHandler.selectedLockEffect) { _, newEffect in
                // Reset effects when switching between effect types
                if newEffect != previousEffect {
                    resetAllEffects()
                    previousEffect = newEffect
                }
            }
            .onChange(of: eventHandler.isLocked) { _, newVal in
                if !newVal {
                    initialized = false
                    resetAllEffects()
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
                    animalType = Int.random(in: 0...7) // Different animal types
                    showAnimals = true
                    debugPrint("Triggering animal effect with type: \(animalType)")
                case .rainbowTrail:
                    rainbowPoints.append(effectPosition)
                    rainbowOpacities.append(0.8) // Start with high opacity
                    
                    // Reduce opacity of existing points
                    for i in 0..<rainbowOpacities.count-1 {
                        rainbowOpacities[i] = max(0.1, rainbowOpacities[i] - 0.07)
                    }
                    
                    // Remove oldest points when too many
                    if rainbowPoints.count > 30 {
                        rainbowPoints.removeFirst()
                        rainbowOpacities.removeFirst()
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
            ForEach(0..<30, id: \.self) { index in
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
    
    // Get a random pastel color for each bubble
    var bubbleColor: Color {
        let colors: [Color] = [
            .blue, .green, .purple, .pink, .orange, .teal, .indigo, .mint
        ]
        return colors[index % colors.count]
    }
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        bubbleColor.opacity(0.7),
                        bubbleColor.opacity(0.2)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 25
                )
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .blur(radius: 1)
                    .offset(x: -5, y: -5)
                    .mask(Circle())
            )
            .frame(width: CGFloat.random(in: 20...70), height: CGFloat.random(in: 20...70))
            .position(x: position.x, y: position.y)
            .offset(offset)
            .scaleEffect(scale)
            .opacity(opacity)
            .onChange(of: count) { _, _ in
                let delay = Double(index) * 0.05
                
                withAnimation(Animation.easeOut(duration: 4.0).delay(delay)) {
                    let randomAngle = Double.random(in: 0...(2 * .pi))
                    let randomDistance = CGFloat.random(in: 100...300)
                    offset = CGSize(
                        width: cos(randomAngle) * randomDistance * 0.5,
                        height: sin(randomAngle) * randomDistance - randomDistance // Always float up
                    )
                    scale = CGFloat.random(in: 0.7...1.5)
                    opacity = Double.random(in: 0.7...1.0)
                }
                
                // Add slight wobble animation
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever().delay(delay)) {
                    offset.width += CGFloat.random(in: -10...10)
                }
                
                // Fade out and reset for reuse
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
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
            ForEach(0..<40, id: \.self) { index in
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
            .shadow(color: .yellow, radius: 5)
            .shadow(color: .yellow, radius: 10) // Double shadow for increased glow
            .frame(width: 40, height: 40)
            .position(x: position.x, y: position.y)
            .offset(offset)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onChange(of: count) { _, _ in
                let delay = Double(index) * 0.03
                
                withAnimation(Animation.easeOut(duration: 2.0).delay(delay)) {
                    let randomAngle = Double.random(in: 0...(2 * .pi))
                    let randomDistance = CGFloat.random(in: 50...250)
                    offset = CGSize(
                        width: cos(randomAngle) * randomDistance,
                        height: sin(randomAngle) * randomDistance
                    )
                    scale = CGFloat.random(in: 0.5...1.5)
                    opacity = Double.random(in: 0.8...1.0) // Higher minimum opacity
                    rotation = Double.random(in: 0...360)
                }
                
                // Twinkle animation
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever().delay(delay)) {
                    scale *= CGFloat.random(in: 0.9...1.3)
                }
                
                // Fade out and reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8 + delay) {
                    withAnimation(.easeOut(duration: 0.7)) {
                        opacity = 0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5 + delay) {
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
    
    // Add a @State counter to force redraw
    @State private var counter: Int = 0
    
    var body: some View {
        ZStack {
            // Display multiple animals at once, with a key to force recreation
            ForEach(0..<3, id: \.self) { index in
                AnimalImage(
                    animalType: (animalType + index) % 8,
                    position: CGPoint(
                        x: position.x + CGFloat.random(in: -50...50),
                        y: position.y + CGFloat.random(in: -50...50)
                    ),
                    uniqueKey: "\(counter)-\(index)" // Force unique instances
                )
            }
        }
        .onChange(of: animalType) { _, _ in
            counter += 1 // Increment counter to create new views
            debugPrint("Animals counter updated: \(counter)")
        }
    }
}

struct AnimalImage: View {
    let animalType: Int
    let position: CGPoint
    let uniqueKey: String // Add a unique identifier
    
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var bounce: CGFloat = 0
    @State private var rotation: Double = 0
    
    var animalEmoji: String {
        // Extended animal emojis collection
        let animals = ["🐶", "🐱", "🐰", "🐼", "🦊", "🐵", "🐨", "🦁"]
        return animals[animalType % animals.count]
    }
    
    var body: some View {
        Text(animalEmoji)
            .font(.system(size: 80))
            .shadow(radius: 2)
            .position(x: position.x, y: position.y)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: bounce)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                debugPrint("Animal appearing: \(animalEmoji) at position \(position) with key \(uniqueKey)")
                
                // Reset state to ensure animations trigger
                scale = 0
                opacity = 0
                bounce = 0
                rotation = 0
                
                // Initial appear animation with slight delay to ensure proper rendering
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                    
                    // Bounce animation
                    withAnimation(Animation.easeInOut(duration: 0.4).repeatCount(5, autoreverses: true)) {
                        bounce = -30
                    }
                    
                    // Rotation wiggle
                    withAnimation(Animation.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
                        rotation = Double.random(in: -15...15)
                    }
                    
                    // Fade out and reset after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.7)) {
                            opacity = 0
                            scale = 0.5
                            bounce = 100 // Drop down animation
                            rotation = Double.random(in: -30...30)
                        }
                    }
                }
            }
            .id(uniqueKey) // Ensure this view is recreated with new key
    }
}

struct RainbowTrailEffectView: View {
    @Binding var isActive: Bool
    @Binding var points: [CGPoint]
    @Binding var opacities: [Double]
    
    // Timer to gradually fade out the trail after inactivity
    @State private var timer: Timer? = nil
    @State private var lastUpdateTime = Date()
    
    var body: some View {
        ZStack {
            // Draw a path through all points
            if points.count > 1 {
                RainbowPath(points: points, opacities: opacities)
            }
        }
        .onAppear {
            // Set up a timer to gradually fade the trail if no new points are added
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                let now = Date()
                if now.timeIntervalSince(lastUpdateTime) > 2.0 && !points.isEmpty {
                    withAnimation {
                        // Reduce opacity of all points gradually
                        for i in 0..<opacities.count {
                            opacities[i] = max(0, opacities[i] - 0.05)
                        }
                        
                        // Remove points that have faded completely
                        while !opacities.isEmpty && opacities[0] <= 0.05 {
                            opacities.removeFirst()
                            if !points.isEmpty {
                                points.removeFirst()
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: points.count) { _, _ in
            lastUpdateTime = Date()
        }
    }
}

struct RainbowPath: View {
    let points: [CGPoint]
    let opacities: [Double]
    
    var body: some View {
        ZStack {
            // Create segments between each pair of points with different opacities
            ForEach(0..<max(0, points.count-1), id: \.self) { index in
                Path { path in
                    path.move(to: points[index])
                    path.addLine(to: points[index+1])
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: getLineWidth(for: index),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .opacity(index < opacities.count ? opacities[index] : 0.7)
                .blur(radius: 2)
                .shadow(color: .white.opacity(0.3), radius: 2)
            }
        }
    }
    
    // Make newer segments thicker for a more dynamic trail
    private func getLineWidth(for index: Int) -> CGFloat {
        let baseWidth: CGFloat = 10
        let position = CGFloat(index) / max(1, CGFloat(points.count - 2))
        // Newer segments (higher indices) are thicker
        return baseWidth * (0.5 + position)
    }
} 