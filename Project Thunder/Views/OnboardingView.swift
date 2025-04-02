import SwiftUI
import PhotosUI

struct OnboardingStep {
    let title: String
    let description: String
}

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var name = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var biography = ""
    @State private var contactInfo = ContactInfo()
    @StateObject private var dataManager = ConsultantDataManager() // Yeni veri yöneticisi
    @State private var showingProfileView = false
    @State private var showingProfileSummary = false
    
    let steps = [
        OnboardingStep(title: "Profile Setup", description: "Let's start with your basic information"),
        OnboardingStep(title: "About You", description: "Tell us about yourself"),
        OnboardingStep(title: "Contact Details", description: "How can clients reach you?"),
        OnboardingStep(title: "References", description: "Share your professional relationships"),
        OnboardingStep(title: "Projects", description: "Showcase your best work"),
        OnboardingStep(title: "Certifications", description: "Add your professional certifications")
    ]
    
    var body: some View {
        VStack {
            // Güvenli progress hesaplama
            ProgressView(value: Double(max(0, min(currentStep, steps.count - 1))), total: Double(steps.count - 1))
                .padding()
            
            // Güvenli index erişimi
            if currentStep >= 0 && currentStep < steps.count {
                Text(LocalizedStringKey(steps[currentStep].title))
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(LocalizedStringKey(steps[currentStep].description))
                    .foregroundColor(.gray)
                    .padding(.bottom)
            }
            
            ScrollView {
                switch currentStep {
                case 0:
                    BasicProfileView(name: $name, selectedItem: $selectedItem, profileImage: $profileImage)
                case 1:
                    BiographyView(biography: $biography)
                case 2:
                    ContactInfoView(contactInfo: $contactInfo)
                case 3:
                    ReferencesView(dataManager: dataManager)
                case 4:
                    ProjectsView(dataManager: dataManager)
                case 5:
                    CertificatesView(dataManager: dataManager)
                default:
                    EmptyView()
                }
            }
            .padding()
            
            HStack {
                if currentStep > 0 {
                    Button(LocalizedStringKey("back")) {
                        withAnimation {
                            // Güvenli geri gitme
                            currentStep = max(0, currentStep - 1)
                        }
                    }
                }
                
                Spacer()
                
                Button(LocalizedStringKey(currentStep >= steps.count - 1 ? "complete_profile" : "next")) {
                    withAnimation {
                        // Güvenli ileri gitme
                        if currentStep < steps.count - 1 {
                            currentStep = min(steps.count - 1, currentStep + 1)
                        } else {
                            showingProfileSummary = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("ThemePrimary"))
            }
            .padding()
        }
        // Hızlı tıklamaları engellemek için minimum animasyon süresi
        .animation(.easeInOut(duration: 0.3), value: currentStep)
        .navigationDestination(isPresented: $showingProfileSummary) {
            ProfileSummaryView(name: $name, profileImage: $profileImage, biography: $biography, contactInfo: $contactInfo, dataManager: dataManager)
        }
    }
}