//
//  AboutView.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 4.1.2025.
//

import SwiftUI


struct AboutView: View {
    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Bundle.applicationName) \(Bundle.main.appVersionLong) (Build \(Bundle.main.appBuild)), All rights reserved")
                Spacer()
            }
            HStack(alignment: .center) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
            }
            Spacer()
            HStack(alignment: .firstTextBaseline) {
                Text("For more information please visit our website")
                Link("https://keyboardlock.app", destination: URL(string: "https://keyboardlock.app")!)
            }
                
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}


#Preview {
    AboutView()
}
