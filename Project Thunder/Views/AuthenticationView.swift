import SwiftUI
import Combine

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showPassword = false
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "bolt.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Color("ThemePrimary"))
            
            Text("Project Thunder")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                HStack {
                    if showPassword {
                        TextField("Şifre", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                    } else {
                        SecureField("Şifre", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
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
                    Text("Giriş Yap")
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
            
            // Kayıt olma bağlantısı
            HStack {
                Text("Hesabın yok mu?")
                    .foregroundColor(.gray)
                
                Button(action: { showRegister = true }) {
                    Text("Kaydol")
                        .fontWeight(.semibold)
                        .foregroundColor(Color("ThemePrimary"))
                }
            }
            
            Spacer()
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
        .sheet(isPresented: $viewModel.twoFactorRequired) {
            TwoFactorView(
                email: email,
                password: password,
                onSuccess: { token, user in
                    // Başarılı giriş sonrası OnboardingView'a yönlendir
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
                dismissButton: .default(Text("Tamam"))
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
    
    var alertTitle = "Hata"
    var alertMessage = "Bir hata oluştu. Lütfen tekrar deneyin."
    
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
                        self?.alertTitle = "Giriş Hatası"
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
                        self?.alertTitle = "Giriş Hatası"
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