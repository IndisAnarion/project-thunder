import Foundation

enum AuthEndpoints: APIEndpoint {
    case register(request: RegisterRequest)
    case login(request: LoginRequest)
    case twoFactorLogin(request: TwoFactorLoginRequest)
    case forgotPassword(request: ForgotPasswordRequest)
    case resetPassword(request: ResetPasswordRequest)
    case confirmEmail(request: ConfirmEmailRequest)
    
    var path: String {
        switch self {
        case .register:
            return "/api/auth/register"
        case .login:
            return "/api/auth/login"
        case .twoFactorLogin:
            return "/api/auth/two-factor-login"
        case .forgotPassword:
            return "/api/auth/forgot-password"
        case .resetPassword:
            return "/api/auth/reset-password"
        case .confirmEmail:
            return "/api/auth/confirm-email"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .register, .login, .twoFactorLogin, .forgotPassword, .resetPassword, .confirmEmail:
            return .post
        }
    }
    
    var bodyParameters: [String: Any]? {
        switch self {
        case .register(let request):
            return [
                "displayName": request.displayName,
                "email": request.email,
                "password": request.password,
                "phoneNumber": request.phoneNumber
            ]
        case .login(let request):
            return [
                "email": request.email,
                "password": request.password
            ]
        case .twoFactorLogin(let request):
            return [
                "email": request.email,
                "password": request.password,
                "twoFactorCode": request.twoFactorCode
            ]
        case .forgotPassword(let request):
            return ["email": request.email]
        case .resetPassword(let request):
            return [
                "userId": request.userId,
                "token": request.token,
                "newPassword": request.newPassword,
                "confirmPassword": request.confirmPassword
            ]
        case .confirmEmail(let request):
            return [
                "userId": request.userId,
                "token": request.token
            ]
        }
    }
    
    // Token var ise authorization header'ını ekleyen yardımcı metot
    func withAuthorization(token: String) -> [String: String] {
        var headers = ["Content-Type": "application/json"]
        headers["Authorization"] = "Bearer \(token)"
        return headers
    }
}