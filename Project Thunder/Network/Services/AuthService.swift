import Foundation
import Combine

protocol AuthServiceProtocol {
    func register(displayName: String, email: String, password: String, phoneNumber: String) -> AnyPublisher<AuthResponse, APIError>
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, APIError>
    func twoFactorLogin(email: String, password: String, twoFactorCode: String) -> AnyPublisher<AuthResponse, APIError>
    func forgotPassword(email: String) -> AnyPublisher<AuthResponse, APIError>
    func resetPassword(userId: String, token: String, newPassword: String, confirmPassword: String) -> AnyPublisher<AuthResponse, APIError>
    func confirmEmail(userId: String, token: String) -> AnyPublisher<AuthResponse, APIError>
    func refreshToken() -> AnyPublisher<AuthResponse, APIError>
    func logout()
}

class AuthService: AuthServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func register(displayName: String, email: String, password: String, phoneNumber: String) -> AnyPublisher<AuthResponse, APIError> {
        let request = RegisterRequest(displayName: displayName, email: email, password: password, phoneNumber: phoneNumber)
        let endpoint = AuthEndpoints.register(request: request)
        
        return networkService.request(endpoint: endpoint, responseType: AuthResponse.self)
                }
    
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, APIError> {
        let request = LoginRequest(email: email, password: password)
        let endpoint = AuthEndpoints.login(request: request)
        
        return networkService.request(endpoint: endpoint, responseType: AuthResponse.self)
                }
    
    func twoFactorLogin(email: String, password: String, twoFactorCode: String) -> AnyPublisher<AuthResponse, APIError> {
        let request = TwoFactorLoginRequest(email: email, password: password, twoFactorCode: twoFactorCode)
        let endpoint = AuthEndpoints.twoFactorLogin(request: request)
        
        return networkService.request(endpoint: endpoint, responseType: AuthResponse.self)
            .handleEvents(receiveOutput: { [weak self] response in
                self?.saveTokens(from: response)
            })
            .eraseToAnyPublisher()
    }
    
    func forgotPassword(email: String) -> AnyPublisher<AuthResponse, APIError> {
        let request = ForgotPasswordRequest(email: email)
        let endpoint = AuthEndpoints.forgotPassword(request: request)
        
        return networkService.request(endpoint: endpoint, responseType: AuthResponse.self)
    }
    
    func resetPassword(userId: String, token: String, newPassword: String, confirmPassword: String) -> AnyPublisher<AuthResponse, APIError> {
        let request = ResetPasswordRequest(userId: userId, token: token, newPassword: newPassword, confirmPassword: confirmPassword)
        let endpoint = AuthEndpoints.resetPassword(request: request)
        
        return networkService.request(endpoint: endpoint, responseType: AuthResponse.self)
    }
    
    func confirmEmail(userId: String, token: String) -> AnyPublisher<AuthResponse, APIError> {
        let request = ConfirmEmailRequest(userId: userId, token: token)
        let endpoint = AuthEndpoints.confirmEmail(request: request)
        
        return networkService.request(endpoint: endpoint, responseType: AuthResponse.self)
    }
    
    // Token yenileme işlemi
    func refreshToken() -> AnyPublisher<AuthResponse, APIError> {
        guard let refreshToken = TokenManager.getRefreshToken() else {
            return Fail(error: APIError.unauthorized("Refresh token not found"))
                .eraseToAnyPublisher()
        }
        
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        let endpoint = AuthEndpoints.refreshToken(request: request)
        
        return networkService.request(endpoint: endpoint, responseType: AuthResponse.self)
            .handleEvents(receiveOutput: { [weak self] response in
                self?.saveTokens(from: response)
            })
            .eraseToAnyPublisher()
    }
    
    // Çıkış yapmak için tokenları temizle
    func logout() {
        TokenManager.clearTokens()
    }
    
    // Token'ları kaydetmek için yardımcı method
    private func saveTokens(from response: AuthResponse) {
        if let accessToken = response.accessToken {
            TokenManager.saveAccessToken(accessToken)
        }
        
        if let refreshToken = response.refreshToken {
            TokenManager.saveRefreshToken(refreshToken)
        }
    }
}