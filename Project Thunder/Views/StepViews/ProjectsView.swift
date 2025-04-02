import SwiftUI

struct ProjectsView: View {
    @ObservedObject var dataManager: ConsultantDataManager
    @State private var showingAddProject = false
    @State private var showingEditProject = false
    @State private var newProject = Project(id: UUID(), title: "", description: "", date: Date())
    @State private var editingProject: Project?
    @State private var editingIndex: Int?
    
    var body: some View {
        VStack {
            // Projeleri listeleyen bölüm
            if dataManager.projects.isEmpty {
                Text(LocalizedStringKey("no_projects"))
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(dataManager.projects.indices, id: \.self) { index in
                        let project = dataManager.projects[index]
                        VStack(alignment: .leading, spacing: 8) {
                            Text(project.title)
                                .font(.headline)
                            Text(project.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(project.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                dataManager.deleteProject(at: index)
                            } label: {
                                Label(LocalizedStringKey("delete"), systemImage: "trash")
                            }
                            
                            Button {
                                editingProject = project
                                editingIndex = index
                                showingEditProject = true
                            } label: {
                                Label(LocalizedStringKey("edit"), systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .frame(height: 300)
            }
            
            // Yeni proje ekleme butonu
            Button(action: { 
                newProject = Project(id: UUID(), title: "", description: "", date: Date())
                showingAddProject = true 
            }) {
                Label(LocalizedStringKey("add_project"), systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("ThemePrimary"))
            .padding()
        }
        .sheet(isPresented: $showingAddProject) {
            NavigationView {
                ProjectFormView(project: $newProject, isEdit: false) {
                    dataManager.addProject(newProject)
                    showingAddProject = false
                }
            }
        }
        .sheet(isPresented: $showingEditProject) {
            if let editingProj = editingProject, let index = editingIndex {
                NavigationView {
                    let binding = Binding<Project>(
                        get: { editingProj },
                        set: { newValue in
                            editingProject = newValue
                        }
                    )
                    
                    ProjectFormView(project: binding, isEdit: true) {
                        if let updatedProj = editingProject {
                            dataManager.updateProject(updatedProj, at: index)
                        }
                        showingEditProject = false
                    }
                }
            }
        }
    }
}

struct ProjectFormView: View {
    @Binding var project: Project
    let isEdit: Bool
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            TextField("Project Title", text: $project.title)
            
            TextEditor(text: $project.description)
                .frame(height: 100)
            
            DatePicker("Date", selection: $project.date, displayedComponents: .date)
        }
        .navigationTitle(isEdit ? "Edit Project" : "Add Project")
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
                .disabled(project.title.isEmpty || project.description.isEmpty)
            }
        }
    }
}