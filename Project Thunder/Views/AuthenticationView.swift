import Combine
import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showPassword = false
    @State private var showForgotPassword = false
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "bolt.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Color("ThemePrimary"))
            
            Text(LocalizedStringKey("app_title"))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField(LocalizedStringKey("email_label"), text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                HStack {
                    if showPassword {
                        TextField(LocalizedStringKey("password_label"), text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                            .overlay(
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 10), alignment: .trailing
                            )
                    } else {
                        SecureField(LocalizedStringKey("password_label"), text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                            .overlay(
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 10), alignment: .trailing
                            )
                    }
                }
                
                HStack {
                    Spacer()
                    Button(action: { showForgotPassword = true }) {
                        Text(LocalizedStringKey("forgot_password_button"))
                            .font(.footnote)
                            .foregroundColor(Color("ThemePrimary"))
                    }
                }
            }
            .padding(.horizontal, 30)
            
            Button(action: {
                viewModel.login(email: email, password: password)
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(LocalizedStringKey("login_button"))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("ThemePrimary"))
            .cornerRadius(10)
            .padding(.horizontal, 30)
            .disabled(viewModel.isLoading || !isFormValid())
            .opacity(isFormValid() ? 1.0 : 0.7)
            
            HStack {
                Text(LocalizedStringKey("no_account_prompt"))
                    .foregroundColor(.gray)
                
                Button(action: { showRegister = true }) {
                    Text(LocalizedStringKey("sign_up_button"))
                        .fontWeight(.semibold)
                        .foregroundColor(Color("ThemePrimary"))
                }
            }
            
            Spacer()
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .sheet(isPresented: $viewModel.twoFactorRequired) {
            TwoFactorView(
                email: email,
                password: password,
                onSuccess: { token, user in
                    viewModel.setAuthenticated(token: token, user: user)
                }
            )
        }
        .navigationDestination(isPresented: $viewModel.isAuthenticated) {
            OnboardingView()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text(LocalizedStringKey("ok_button")))
            )
        }
    }
    
    private func isFormValid() -> Bool {
        return !email.isEmpty && email.contains("@") && !password.isEmpty
    }
}

// View Model
class AuthenticationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isAuthenticated = false
    @Published var twoFactorRequired = false
    @Published var showAlert = false
    @Published var accessToken: String?
    @Published var user: UserInfo?
    
    var alertTitle = "login_error_title".localized
    var alertMessage = "login_error_message".localized
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService()
    
    func login(email: String, password: String) {
        isLoading = true
        
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.showAlert = true
                        self?.alertTitle = "login_error_title".localized
                        self?.alertMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    if response.status == "TwoFactorRequired" {
                        // İki faktörlü doğrulama gerekiyor
                        self?.twoFactorRequired = true
                    } else if response.status == "Success" {
                        // Direkt giriş başarılı (2FA gerekmeyen durumlar için)
                        if let token = response.accessToken, let user = response.user {
                            self?.setAuthenticated(token: token, user: user)
                        }
                    } else {
                        // Beklenmeyen durum
                        self?.showAlert = true
                        self?.alertTitle = "error_title".localized
                        self?.alertMessage = response.message ?? "Giriş sırasında bir hata oluştu."
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func setAuthenticated(token: String, user: UserInfo) {
        self.accessToken = token
        self.user = user
        
        // Kullanıcı bilgilerini ve token'ı kaydet
        saveUserData(token: token, user: user)
        
        // Kimlik doğrulama durumunu güncelle
        self.isAuthenticated = true
    }
    
    private func saveUserData(token: String, user: UserInfo) {
        // Token ve kullanıcı bilgilerini UserDefaults veya Keychain'e kaydet
        UserDefaults.standard.set(token, forKey: "accessToken")
        // Kullanıcı bilgilerini JSON olarak kodla ve kaydet
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "userData")
        }
    }
}