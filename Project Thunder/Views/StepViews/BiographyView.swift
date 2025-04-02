import SwiftUI

struct BiographyView: View {
    @Binding var biography: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("tell_about_expertise"))
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextEditor(text: $biography)
                .frame(height: 200)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            Text(String(format: NSLocalizedString("character_count", comment: "Character count"), biography.count))
                .font(.caption)
                .foregroundColor(biography.count > 500 ? .red : .gray)
        }
        .padding()
    }
}