import SwiftUI
import Combine

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RegisterViewModel()
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title3)
                            .foregroundColor(Color("ThemePrimary"))
                    }
                    
                    Spacer()
                    
                    Text(LocalizedStringKey("register_title"))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Simetrik görünmesi için boş bir View
                    Image(systemName: "arrow.left")
                        .font(.title3)
                        .foregroundColor(.clear)
                }
                .padding(.horizontal)
                
                // Logo
                Image(systemName: "bolt.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color("ThemePrimary"))
                
                VStack(spacing: 18) {
                    // Ad Soyad
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("name_label"))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField(LocalizedStringKey("name_label"), text: $displayName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .textContentType(.name)
                    }
                    
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("email_label"))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField(LocalizedStringKey("email_label"), text: $email)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Telefon
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("phone_number"))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField(LocalizedStringKey("phone_number"), text: $phoneNumber)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                    
                    // Şifre
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("password_label"))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            if showPassword {
                                TextField(LocalizedStringKey("password_label"), text: $password)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField(LocalizedStringKey("password_label"), text: $password)
                                    .textContentType(.newPassword)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Şifre Tekrar
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("confirm_password"))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            if showConfirmPassword {
                                TextField(LocalizedStringKey("confirm_password"), text: $confirmPassword)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField(LocalizedStringKey("confirm_password"), text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Kaydol Butonu
                Button(action: {
                    register()
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(LocalizedStringKey("register_button"))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("ThemePrimary"))
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(viewModel.isLoading || !isFormValid())
                .opacity(isFormValid() ? 1.0 : 0.7)
                
                // Zaten hesabınız var mı? Giriş yap
                HStack {
                    Text(LocalizedStringKey("already_have_account"))
                        .foregroundColor(.gray)
                    
                    Button(action: { dismiss() }) {
                        Text(LocalizedStringKey("login_button"))
                            .fontWeight(.semibold)
                            .foregroundColor(Color("ThemePrimary"))
                    }
                }
                .padding(.bottom)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text(LocalizedStringKey("ok_button")))
            )
        }
        .alert(isPresented: $viewModel.showSuccessAlert) {
            Alert(
                title: Text(LocalizedStringKey("registration_successful")),
                message: Text(LocalizedStringKey("redirecting_to_login")),
                dismissButton: .default(Text(LocalizedStringKey("ok_button"))) {
                    dismiss()
                }
            )
        }
        .onReceive(viewModel.$error) { error in
            if let _ = error {
                showAlert = true
            }
        }
    }
    
    private func isFormValid() -> Bool {
        return !displayName.isEmpty &&
               !email.isEmpty && email.contains("@") &&
               !phoneNumber.isEmpty &&
               !password.isEmpty && password.count >= 6 &&
               password == confirmPassword
    }
    
    private func register() {
        viewModel.register(
            displayName: displayName,
            email: email,
            password: password,
            phoneNumber: phoneNumber
        )
    }
}

class RegisterViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: APIError?
    @Published var showSuccessAlert = false
    
    var alertTitle = "error_title".localized
    var alertMessage = "error_message".localized
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService()
    
    func register(displayName: String, email: String, password: String, phoneNumber: String) {
        isLoading = true
        
        authService.register(displayName: displayName, email: email, password: password, phoneNumber: phoneNumber)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.error = error
                        self?.alertTitle = "Kayıt Hatası"
                        self?.alertMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    if response.status == "Success" {
                        self?.showSuccessAlert = true
                    } else {
                        self?.error = APIError.serverError(response.message ?? "Kayıt sırasında bir hata oluştu.")
                        self?.alertTitle = "Kayıt Hatası"
                        self?.alertMessage = response.message ?? "Kayıt sırasında bir hata oluştu."
                    }
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    RegisterView()
}