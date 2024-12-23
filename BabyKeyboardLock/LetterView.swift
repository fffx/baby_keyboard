//
//  Untitled.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import SwiftUI
import AppKit


struct LetterView: View {
    let letter: String
    @State private var rotation = 0.0
    @State private var scale = 0.1
    @State private var hue = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            Text(letter)
                .font(.system(size: geometry.size.height * 0.8, weight: .bold, design: .rounded))
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            Color(hue: hue, saturation: 0.8, brightness: 1),
                            Color(hue: (hue + 0.2).truncatingRemainder(dividingBy: 1), saturation: 0.8, brightness: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .white.opacity(0.5), radius: 20)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        scale = 1.0
                        rotation = Double.random(in: -20...20)
                    }
                    withAnimation(.linear(duration: 1.0).repeatForever()) {
                        hue = Double.random(in: 0...1)
                    }
                }
        }
        .background(Color.black.opacity(0.01))
    }
}
