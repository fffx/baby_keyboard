import SwiftUI

struct FlashcardStylePicker: View {
    @Binding var selectedStyle: FlashcardStyle
    
    var body: some View {
        Picker("Style", selection: $selectedStyle) {
            ForEach(FlashcardStyle.allCases, id: \.self) { style in
                Text(style.title).tag(style)
            }
        }
        .pickerStyle(.segmented)
    }
} 