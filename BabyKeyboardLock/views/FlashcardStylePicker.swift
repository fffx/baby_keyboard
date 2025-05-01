import SwiftUI

struct FlashcardStylePicker: View {
    @Binding var selectedStyle: FlashcardStyle
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(FlashcardStyle.allCases, id: \.self) { style in
                Button(action: {
                    selectedStyle = style
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: style.icon)
                            .font(.system(size: 24))
                        
                        Text(style.title)
                            .font(.caption)
                    }
                    .frame(width: 85)
                    .padding(.vertical, 12)
                    .background(selectedStyle == style ? Color.accentColor : Color.clear)
                    .foregroundColor(selectedStyle == style ? .white : .primary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
    }
} 