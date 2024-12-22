//
//  Firework.swift
//  baby_keyboard
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
    @State private var counter: Int = 0
    @State private var initialized = false
    @State private var buttonPosition: CGPoint = .zero
    
    @State private var windowSize: CGSize = .zero
    @EnvironmentObject var eventHandler: EventHandler
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                Button("") {
                   counter += 1
                }
                .background(.clear)
                .buttonStyle(PlainButtonStyle())
                .confettiCannon(counter: $counter)
                .position(x: buttonPosition.x, y: buttonPosition.y)
            }
            .onAppear {
                windowSize = geometry.size
            }
            .onReceive(eventHandler.$lastKeyString) { _ in
                if !initialized {
                    self.initialized = true
                    return
                }
                
                guard let letter = eventHandler.lastKeyString.first, letter.isLetter || letter.isNumber else { return }

                counter += 1
                
              let randomX = CGFloat.random(in: 0...geometry.size.width)
              let randomY = CGFloat.random(in: 0...geometry.size.height)
              
              // Update the button's position
              buttonPosition = CGPoint(x: randomX, y: randomY)
                
                guard let nsSound = NSSound(named: "confetti-cannon") else { return }
                (nsSound.copy() as! NSSound).play()
            }
        }
        .fullscreenTransparentWindow()
    }
}
