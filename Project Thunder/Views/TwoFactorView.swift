import SwiftUI
import Combine

struct TwoFactorView: View {
    let email: String
    let password: String
    let onSuccess: (String, UserInfo) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TwoFactorViewModel()
    
    @State private var code: String = ""
    
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
                
                Text(LocalizedStringKey("two_factor_title"))
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
            Image(systemName: "lock.shield.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color("ThemePrimary"))
            
            // Açıklama Metni
            Text(LocalizedStringKey("two_factor_description"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
            Text(email)
                .font(.headline)
                .foregroundColor(Color("ThemePrimary"))
            
            // Kod Girişi
            OTPTextField(code: $code, length: 6)
                .padding(.vertical)
            
            // Doğrula Butonu
            Button(action: {
                viewModel.verifyCode(email: email, password: password, code: code)
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(LocalizedStringKey("verify_button"))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("ThemePrimary"))
            .cornerRadius(10)
            .padding(.horizontal, 30)
            .disabled(viewModel.isLoading || code.count < 6)
            .opacity(code.count == 6 ? 1.0 : 0.7)
            
            // Kodu Yeniden Gönder
            Button(action: {
                viewModel.resendCode(email: email, password: password)
            }) {
                Text(LocalizedStringKey("resend_code"))
                    .fontWeight(.medium)
                    .foregroundColor(Color("ThemePrimary"))
            }
            .padding(.top, 5)
            .disabled(viewModel.isLoading || viewModel.isResendDisabled)
            .opacity(viewModel.isResendDisabled ? 0.5 : 1.0)
            
            if viewModel.isResendDisabled {
                Text(String(format: NSLocalizedString("resend_code_timer", comment: "Resend code timer"), viewModel.resendCountdown))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text(LocalizedStringKey("ok_button")))
            )
        }
        .onReceive(viewModel.$loginSuccess) { success in
            if success, let token = viewModel.accessToken, let user = viewModel.user {
                onSuccess(token, user)
                dismiss()
            }
        }
    }
}

class TwoFactorViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var loginSuccess = false
    @Published var accessToken: String?
    @Published var user: UserInfo?
    @Published var isResendDisabled = false
    @Published var resendCountdown = 60
    
    var alertTitle = "Hata"
    var alertMessage = "Bir hata oluştu. Lütfen tekrar deneyin."
    
    private var cancellables = Set<AnyCancellable>()
    private var resendTimer: Timer?
    private let authService = AuthService()
    
    func verifyCode(email: String, password: String, code: String) {
        isLoading = true
        
        authService.twoFactorLogin(email: email, password: password, twoFactorCode: code)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.showAlert = true
                        self?.alertTitle = "Doğrulama Hatası"
                        self?.alertMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    if response.status == "Success" {
                        self?.accessToken = response.accessToken
                        self?.user = response.user
                        self?.loginSuccess = true
                    } else {
                        self?.showAlert = true
                        self?.alertTitle = "Doğrulama Hatası"
                        self?.alertMessage = response.message ?? "Doğrulama sırasında bir hata oluştu."
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func resendCode(email: String, password: String) {
        isLoading = true
        
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.showAlert = true
                        self?.alertTitle = "Kod Gönderme Hatası"
                        self?.alertMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    if response.status == "TwoFactorRequired" {
                        self?.showAlert = true
                        self?.alertTitle = "Başarılı"
                        self?.alertMessage = "Doğrulama kodu tekrar gönderildi."
                        
                        // Yeniden gönderimi devre dışı bırak
                        self?.startResendCooldown()
                    } else {
                        self?.showAlert = true
                        self?.alertTitle = "Kod Gönderme Hatası"
                        self?.alertMessage = response.message ?? "Kod gönderme sırasında bir hata oluştu."
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func startResendCooldown() {
        isResendDisabled = true
        resendCountdown = 60
        
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.resendCountdown > 0 {
                self.resendCountdown -= 1
            } else {
                self.isResendDisabled = false
                timer.invalidate()
            }
        }
    }
    
    deinit {
        resendTimer?.invalidate()
    }
}

struct OTPTextField: View {
    @Binding var code: String
    let length: Int
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<length, id: \.self) { index in
                OTPDigitField(
                    index: index,
                    code: $code,
                    length: length,
                    isFocused: _isFocused
                )
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

struct OTPDigitField: View {
    let index: Int
    @Binding var code: String
    let length: Int
    @FocusState var isFocused: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            
            if code.count > index {
                let startIndex = code.index(code.startIndex, offsetBy: index)
                let endIndex = code.index(code.startIndex, offsetBy: index + 1)
                let digit = String(code[startIndex..<endIndex])
                
                Text(digit)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .frame(width: 45, height: 60)
        .overlay(
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { newValue in
                    // Sayısal değer kontrolü
                    code = newValue.filter { "0123456789".contains($0) }
                    
                    // Maksimum uzunluk kontrolü
                    if code.count > length {
                        code = String(code.prefix(length))
                    }
                }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }
}