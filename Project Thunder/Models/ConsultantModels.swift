import Foundation
import Combine

struct ContactInfo {
    var phone = ""
    var email = ""
    var location = ""
    var website = ""
}

struct Reference: Identifiable, Equatable {
    var id = UUID()
    var companyName: String
    var contactPerson: String
    var position: String
    var contactInfo: String
    
    static func == (lhs: Reference, rhs: Reference) -> Bool {
        return lhs.id == rhs.id &&
               lhs.companyName == rhs.companyName &&
               lhs.contactPerson == rhs.contactPerson &&
               lhs.position == rhs.position &&
               lhs.contactInfo == rhs.contactInfo
    }
}

struct Project: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var date: Date
}

struct Certificate: Identifiable {
    var id = UUID()
    var title: String
    var issuingOrganization: String
    var issueDate: Date
    var documentURL: URL?
}

// Yeni model manager sınıfları
class ConsultantDataManager: ObservableObject {
    @Published var references: [Reference] = []
    @Published var projects: [Project] = []
    @Published var certificates: [Certificate] = []
    
    // References için yardımcı fonksiyonlar
    func addReference(_ reference: Reference) {
        references.append(reference)
    }
    
    func updateReference(_ reference: Reference, at index: Int) {
        guard index < references.count else { return }
        references[index] = reference
    }
    
    func deleteReference(at index: Int) {
        guard index < references.count else { return }
        references.remove(at: index)
    }
    
    // Projects için yardımcı fonksiyonlar
    func addProject(_ project: Project) {
        projects.append(project)
    }
    
    func updateProject(_ project: Project, at index: Int) {
        guard index < projects.count else { return }
        projects[index] = project
    }
    
    func deleteProject(at index: Int) {
        guard index < projects.count else { return }
        projects.remove(at: index)
    }
    
    // Certificates için yardımcı fonksiyonlar
    func addCertificate(_ certificate: Certificate) {
        certificates.append(certificate)
    }
    
    func updateCertificate(_ certificate: Certificate, at index: Int) {
        guard index < certificates.count else { return }
        certificates[index] = certificate
    }
    
    func deleteCertificate(at index: Int) {
        guard index < certificates.count else { return }
        certificates.remove(at: index)
    }
}