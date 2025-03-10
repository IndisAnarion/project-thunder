import SwiftUI
import UniformTypeIdentifiers

struct CertificatesView: View {
    @ObservedObject var dataManager: ConsultantDataManager
    @State private var showingAddCertificate = false
    @State private var showingEditCertificate = false
    @State private var newCertificate = Certificate(id: UUID(), title: "", issuingOrganization: "", issueDate: Date(), documentURL: nil)
    @State private var editingCertificate: Certificate?
    @State private var editingIndex: Int?
    
    var body: some View {
        VStack {
            // Sertifikaları listeleyen bölüm
            if dataManager.certificates.isEmpty {
                Text("No certificates added yet")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(dataManager.certificates.indices, id: \.self) { index in
                        let certificate = dataManager.certificates[index]
                        VStack(alignment: .leading, spacing: 8) {
                            Text(certificate.title)
                                .font(.headline)
                            Text(certificate.issuingOrganization)
                                .font(.subheadline)
                            Text(certificate.issueDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if certificate.documentURL != nil {
                                Label("Document Attached", systemImage: "doc.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                dataManager.deleteCertificate(at: index)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                editingCertificate = certificate
                                editingIndex = index
                                showingEditCertificate = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .frame(height: 300)
            }
            
            // Yeni sertifika ekleme butonu
            Button(action: { 
                newCertificate = Certificate(id: UUID(), title: "", issuingOrganization: "", issueDate: Date(), documentURL: nil)
                showingAddCertificate = true 
            }) {
                Label("Add Certificate", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("ThemePrimary"))
            .padding()
        }
        .sheet(isPresented: $showingAddCertificate) {
            NavigationView {
                CertificateFormView(certificate: $newCertificate, isEdit: false) {
                    dataManager.addCertificate(newCertificate)
                    showingAddCertificate = false
                }
            }
        }
        .sheet(isPresented: $showingEditCertificate) {
            if let editingCert = editingCertificate, let index = editingIndex {
                NavigationView {
                    let binding = Binding<Certificate>(
                        get: { editingCert },
                        set: { newValue in
                            editingCertificate = newValue
                        }
                    )
                    
                    CertificateFormView(certificate: binding, isEdit: true) {
                        if let updatedCert = editingCertificate {
                            dataManager.updateCertificate(updatedCert, at: index)
                        }
                        showingEditCertificate = false
                    }
                }
            }
        }
    }
}

struct CertificateFormView: View {
    @Binding var certificate: Certificate
    let isEdit: Bool
    let onSave: () -> Void
    @State private var showingDocumentPicker = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            TextField("Certificate Title", text: $certificate.title)
            TextField("Issuing Organization", text: $certificate.issuingOrganization)
            DatePicker("Issue Date", selection: $certificate.issueDate, displayedComponents: .date)
            
            Button(action: { showingDocumentPicker = true }) {
                Label(certificate.documentURL != nil ? "Change Document" : "Attach Document", 
                      systemImage: certificate.documentURL != nil ? "doc.badge.arrow.up" : "doc.badge.plus")
            }
        }
        .navigationTitle(isEdit ? "Edit Certificate" : "Add Certificate")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEdit ? "Save" : "Add") {
                    onSave()
                }
                .disabled(certificate.title.isEmpty || certificate.issuingOrganization.isEmpty)
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                certificate.documentURL = url
            case .failure:
                break
            }
        }
    }
}
