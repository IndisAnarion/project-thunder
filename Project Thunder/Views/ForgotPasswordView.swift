import SwiftUI
import Combine

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @State private var email = ""
    @State private var showResetPasswordView = false
    @State private var userId = ""
    @State private var token = ""
    
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
                
                Text(LocalizedStringKey("forgot_password_title"))
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
            Image(systemName: "lock.rotation")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color("ThemePrimary"))
            
            // Açıklama
            Text(LocalizedStringKey("forgot_password_description"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
            // Email alanı
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("email_label"))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField(LocalizedStringKey("email_label"), text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding(.horizontal)
            
            // Gönder butonu
            Button(action: { viewModel.forgotPassword(email: email) }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(LocalizedStringKey("send_link_button"))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("ThemePrimary"))
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(viewModel.isLoading || !isEmailValid())
            .opacity(isEmailValid() ? 1.0 : 0.7)
            
            Spacer()
        }
        .navigationDestination(isPresented: $showResetPasswordView) {
            ResetPasswordView(userId: userId, token: token)
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text(LocalizedStringKey("ok_button"))){
                    if viewModel.isSuccess {
                        dismiss()
                    }
                }
            )
        }
    }
    
    private func isEmailValid() -> Bool {
        return !email.isEmpty && email.contains("@")
    }
}

class ForgotPasswordViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var isSuccess = false
    
    var alertTitle = "Bilgi"
    var alertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService()
    
    func forgotPassword(email: String) {
        isLoading = true
        
        authService.forgotPassword(email: email)
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
                        self?.alertMessage = response.message ?? "Email adresinize şifre sıfırlama bağlantısı gönderildi."
                    } else {
                        self?.alertTitle = "Bilgi"
                        self?.alertMessage = response.message ?? "İşlem sırasında bir hata oluştu."
                    }
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    ForgotPasswordView()
}