import SwiftUI

struct ContactInfoView: View {
    @Binding var contactInfo: ContactInfo
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Phone Number", text: $contactInfo.phone)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)
            
            TextField("Email", text: $contactInfo.email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            TextField("Location", text: $contactInfo.location)
                .textFieldStyle(.roundedBorder)
            
            TextField("Website (Optional)", text: $contactInfo.website)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .autocapitalization(.none)
        }
        .padding()
    }
}