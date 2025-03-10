import SwiftUI
import PhotosUI

struct BasicProfileView: View {
    @Binding var name: String
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var profileImage: Image?
    
    var body: some View {
        VStack(spacing: 20) {
            PhotosPicker(selection: $selectedItem) {
                if let profileImage {
                    profileImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color("ThemePrimary"), lineWidth: 2))
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Color("ThemePrimary"))
                                .font(.system(size: 40))
                        }
                }
            }
            .onChange(of: selectedItem) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
            
            TextField("Your Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
        }
    }
}