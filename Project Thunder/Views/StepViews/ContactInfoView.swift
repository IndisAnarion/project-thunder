import SwiftUI

struct ContactInfoView: View {
    @Binding var contactInfo: ContactInfo
    
    var body: some View {
        VStack(spacing: 20) {
            TextField(LocalizedStringKey("phone_number"), text: $contactInfo.phone)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)
            
            TextField(LocalizedStringKey("email_label"), text: $contactInfo.email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            TextField(LocalizedStringKey("location"), text: $contactInfo.location)
                .textFieldStyle(.roundedBorder)
            
            TextField(LocalizedStringKey("website_optional"), text: $contactInfo.website)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .autocapitalization(.none)
        }
        .padding()
    }
}