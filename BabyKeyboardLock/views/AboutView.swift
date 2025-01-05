//
//  AboutView.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 4.1.2025.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(Bundle.applicationName) \(Bundle.main.appVersionLong), All rights reserved")
            }
            Spacer()
            HStack {
                Text("For more information please visit")
                Link("https://keyboardlock.app", destination: URL(string: "https://keyboardlock.app")!)
            }
                
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}


#Preview {
    AboutView()
}
