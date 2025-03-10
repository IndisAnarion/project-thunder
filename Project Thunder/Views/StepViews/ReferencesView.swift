import SwiftUI

struct ReferencesView: View {
    @ObservedObject var dataManager: ConsultantDataManager
    @State private var showingAddReference = false
    @State private var showingEditReference = false
    @State private var newReference = Reference(id: UUID(), companyName: "", contactPerson: "", position: "", contactInfo: "")
    @State private var editingReference: Reference?
    @State private var editingIndex: Int?
    
    var body: some View {
        VStack {
            // Referansları listeleyen bölüm
            if dataManager.references.isEmpty {
                Text("No references added yet")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(dataManager.references.indices, id: \.self) { index in
                        let reference = dataManager.references[index]
                        VStack(alignment: .leading, spacing: 8) {
                            Text(reference.companyName)
                                .font(.headline)
                            Text(reference.contactPerson)
                                .font(.subheadline)
                            Text(reference.position)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                dataManager.deleteReference(at: index)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                editingReference = reference
                                editingIndex = index
                                showingEditReference = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .frame(height: 300)
                .listStyle(DefaultListStyle())
            }
            
            // Yeni referans ekleme butonu
            Button(action: { 
                newReference = Reference(id: UUID(), companyName: "", contactPerson: "", position: "", contactInfo: "")
                showingAddReference = true 
            }) {
                Label("Add Reference", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("ThemePrimary"))
            .padding()
        }
        .sheet(isPresented: $showingAddReference) {
            NavigationView {
                ReferenceFormView(reference: $newReference, isEdit: false) {
                    dataManager.addReference(newReference)
                    showingAddReference = false
                }
            }
        }
        .sheet(isPresented: $showingEditReference) {
            if let index = editingIndex, editingReference != nil {        
                NavigationView {
                    let binding = Binding<Reference>(
                        get: { self.editingReference! },
                        set: { self.editingReference = $0 }
                    )
                    
                    ReferenceFormView(reference: binding, isEdit: true) {
                        if let updatedRef = editingReference {
                            dataManager.updateReference(updatedRef, at: index)
                        }
                        showingEditReference = false
                    }
                }
            }
        }
    }
}

struct ReferenceFormView: View {
    @Binding var reference: Reference
    let isEdit: Bool
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            TextField("Company Name", text: $reference.companyName)
            TextField("Contact Person", text: $reference.contactPerson)
            TextField("Position", text: $reference.position)
            TextField("Contact Information", text: $reference.contactInfo)
        }
        .navigationTitle(isEdit ? "Edit Reference" : "Add Reference")
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
                .disabled(reference.companyName.isEmpty || reference.contactPerson.isEmpty)
            }
        }
    }
}