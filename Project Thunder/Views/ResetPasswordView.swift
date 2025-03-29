import SwiftUI
import Combine

struct ResetPasswordView: View {
    let userId: String
    let token: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ResetPasswordViewModel()
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        VStack(spacing: 25) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.title3)
                        .foregroundColor(Color("ThemePrimary"))
                }
                
                Spacer()
                
                Text("Şifre Sıfırlama")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Simetrik görünmesi için boş bir View
                Image(systemName: "arrow.left")
                    .font(.title3)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Logo
            Image(systemName: "lock.shield")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color("ThemePrimary"))
            
            // Açıklama
            Text("Lütfen yeni şifrenizi girin")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
            // Yeni şifre
            VStack(alignment: .leading, spacing: 8) {
                Text("Yeni Şifre")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    if showNewPassword {
                        TextField("Yeni Şifre", text: $newPassword)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Yeni Şifre", text: $newPassword)
                            .textContentType(.newPassword)
                    }
                    
                    Button(action: { showNewPassword.toggle() }) {
                        Image(systemName: showNewPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Şifre tekrar
            VStack(alignment: .leading, spacing: 8) {
                Text("Şifre Tekrar")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    if showConfirmPassword {
                        TextField("Şifre Tekrar", text: $confirmPassword)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Şifre Tekrar", text: $confirmPassword)
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
            .padding(.horizontal)
            
            // Hata durumu (şifreler uyuşmuyorsa)
            if !passwordsMatch() && !confirmPassword.isEmpty {
                Text("Şifreler eşleşmiyor!")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // Sıfırla butonu
            Button(action: {
                viewModel.resetPassword(
                    userId: userId,
                    token: token,
                    newPassword: newPassword,
                    confirmPassword: confirmPassword
                )
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Şifremi Sıfırla")
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
            
            Spacer()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("Tamam")) {
                    if viewModel.isSuccess {
                        dismiss()
                    }
                }
            )
        }
    }
    
    private func isFormValid() -> Bool {
        return !newPassword.isEmpty && newPassword.count >= 6 && passwordsMatch()
    }
    
    private func passwordsMatch() -> Bool {
        return newPassword == confirmPassword
    }
}

class ResetPasswordViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var isSuccess = false
    
    var alertTitle = "Bilgi"
    var alertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService()
    
    func resetPassword(userId: String, token: String, newPassword: String, confirmPassword: String) {
        isLoading = true
        
        authService.resetPassword(userId: userId, token: token, newPassword: newPassword, confirmPassword: confirmPassword)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.showAlert = true
                        self?.alertTitle = "Hata"
                        self?.alertMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.showAlert = true
                    
                    if response.status == "Success" {
                        self?.isSuccess = true
                        self?.alertTitle = "Başarılı"
                        self?.alertMessage = response.message ?? "Şifreniz başarıyla sıfırlandı. Şimdi giriş yapabilirsiniz."
                    } else {
                        self?.alertTitle = "Hata"
                        self?.alertMessage = response.message ?? "Şifre sıfırlama sırasında bir hata oluştu."
                    }
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    ResetPasswordView(userId: "test-user-id", token: "test-token")
}