//
//  ContentView.swift
//  baby_keyboard
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            if #available(macOS 12.0, *) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
            } else {
                // Fallback on earlier versions
            }
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
