import SwiftUI

struct ProfileSummaryView: View {
    @Binding var name: String
    @Binding var profileImage: Image?
    @Binding var biography: String
    @Binding var contactInfo: ContactInfo
    @ObservedObject var dataManager: ConsultantDataManager
    @State private var showingOnboarding = false
    
    // State variables for interactive elements
    @State private var expandedSection: String? = nil
    @State private var animateProfile = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Image Section with animation
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color("ThemePrimary").opacity(0.2))
                                .frame(width: 130, height: 130)
                                .scaleEffect(animateProfile ? 1.1 : 1.0)
                            
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color("ThemePrimary"), lineWidth: 3))
                                    .shadow(color: Color("ThemePrimary").opacity(0.5), radius: animateProfile ? 8 : 0)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(Color("ThemePrimary"))
                                    .shadow(color: Color("ThemePrimary").opacity(0.5), radius: animateProfile ? 8 : 0)
                            }
                        }
                        .onAppear {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).repeatForever(autoreverses: true)) {
                                animateProfile = true
                            }
                        }
                        
                        Text(name.isEmpty ? "Your Name" : name)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(.top, 8)
                    }
                    .padding(.top, 20)
                    
                    // Biography Card
                    ProfileCard(
                        title: "Biography",
                        isExpanded: expandedSection == "bio",
                        onTap: { toggleSection("bio") }
                    ) {
                        Text(biography.isEmpty ? "No biography added yet." : biography)
                            .font(.body)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 4)
                    }
                    
                    // Contact Information Card
                    ProfileCard(
                        title: "Contact Information",
                        isExpanded: expandedSection == "contact",
                        onTap: { toggleSection("contact") }
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ContactRow(icon: "phone.fill", title: "Phone", value: contactInfo.phone.isEmpty ? "Not provided" : contactInfo.phone)
                            ContactRow(icon: "envelope.fill", title: "Email", value: contactInfo.email.isEmpty ? "Not provided" : contactInfo.email)
                            ContactRow(icon: "location.fill", title: "Location", value: contactInfo.location.isEmpty ? "Not provided" : contactInfo.location)
                            if !contactInfo.website.isEmpty {
                                ContactRow(icon: "link", title: "Website", value: contactInfo.website)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // References Card
                    ProfileCard(
                        title: "References",
                        isExpanded: expandedSection == "references",
                        onTap: { toggleSection("references") },
                        count: dataManager.references.count
                    ) {
                        if dataManager.references.isEmpty {
                            EmptyStateView(message: "No references added yet", icon: "person.2")
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(dataManager.references) { reference in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(reference.companyName)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(Color("ThemePrimary"))
                                                .font(.caption)
                                            Text(reference.contactPerson)
                                                .font(.caption)
                                        }
                                        
                                        HStack {
                                            Image(systemName: "briefcase.fill")
                                                .foregroundColor(Color("ThemeSecondary"))
                                                .font(.caption)
                                            Text(reference.position)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(Color(.systemBackground).opacity(0.7))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Projects Card
                    ProfileCard(
                        title: "Projects",
                        isExpanded: expandedSection == "projects",
                        onTap: { toggleSection("projects") },
                        count: dataManager.projects.count
                    ) {
                        if dataManager.projects.isEmpty {
                            EmptyStateView(message: "No projects added yet", icon: "rectangle.stack.fill")
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(dataManager.projects) { project in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text(project.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(expandedSection == "projects" ? nil : 2)
                                        
                                        HStack {
                                            Image(systemName: "calendar")
                                                .foregroundColor(Color("ThemeSecondary"))
                                                .font(.caption)
                                            Text(project.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(Color(.systemBackground).opacity(0.7))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Certificates Card
                    ProfileCard(
                        title: "Certificates",
                        isExpanded: expandedSection == "certificates",
                        onTap: { toggleSection("certificates") },
                        count: dataManager.certificates.count
                    ) {
                        if dataManager.certificates.isEmpty {
                            EmptyStateView(message: "No certificates added yet", icon: "doc.text.fill")
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(dataManager.certificates) { certificate in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(certificate.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text(certificate.issuingOrganization)
                                            .font(.caption)
                                        
                                        HStack {
                                            Image(systemName: "calendar")
                                                .foregroundColor(Color("ThemeSecondary"))
                                                .font(.caption)
                                            Text(certificate.issueDate.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        if certificate.documentURL != nil {
                                            HStack {
                                                Image(systemName: "doc.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.caption)
                                                Text("Document Attached")
                                                    .font(.caption2)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(Color(.systemBackground).opacity(0.7))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Edit Button with improved style and haptic feedback
                    Button(action: { 
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        showingOnboarding = true 
                    }) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                            Text("Edit Profile")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("ThemePrimary"), Color("ThemeSecondary")]),
                                startPoint: .leading, 
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: Color("ThemePrimary").opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal)
                .frame(minHeight: geometry.size.height)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { expandedSection = nil }) {
                            Label("Collapse All", systemImage: "rectangle.compress.vertical")
                        }
                        Button(action: { 
                            withAnimation {
                                expandedSection = "bio"
                            }
                        }) {
                            Label("Biography", systemImage: "text.justify")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showingOnboarding) {
            OnboardingView()
        }
    }
    
    private func toggleSection(_ section: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            expandedSection = (expandedSection == section) ? nil : section
        }
    }
}

// Helper components for better UI organization
struct ProfileCard<Content: View>: View {
    let title: String
    let isExpanded: Bool
    let onTap: () -> Void
    let content: Content
    var count: Int? = nil
    
    init(
        title: String,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        count: Int? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.count = count
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let count = count, count > 0 {
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color("ThemePrimary"))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut, value: isExpanded)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            
            // Content
            if isExpanded {
                Divider()
                
                content
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color("ThemePrimary"))
                .frame(width: 24, height: 24)
                .background(Color("ThemePrimary").opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
        }
    }
}

struct EmptyStateView: View {
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(Color("ThemeSecondary").opacity(0.7))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
