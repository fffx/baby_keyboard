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
                .confettiCannon(
                    counter: $counter,
                    num: Int.random(in: 15...40),
                    confettiSize: 15,
                    rainHeight: geometry.size.height,
                    radius: 500
                )
                .position(x: buttonPosition.x, y: buttonPosition.y)
            }
            .padding()
            .presentedWindowStyle(.hiddenTitleBar)
            .onAppear {
                windowSize = geometry.size
                debugPrint("-------- windowSize: \(windowSize)")
            }
            .onReceive(eventHandler.$lastKeyString) { _ in
                if !initialized {
                    self.initialized = true
                    return
                }
                if(!eventHandler.isLocked) { return }
                
                // ##### Confetti handler
                if eventHandler.selectedLockEffect != .confettiConnon { return }
                
                guard let letter = eventHandler.lastKeyString.first, letter.isLetter || letter.isNumber else { return }
                
                counter += 1
                debugPrint("counter increase -------- \(counter)")
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
