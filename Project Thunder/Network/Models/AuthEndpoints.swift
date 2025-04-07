import Foundation

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

enum AuthEndpoints: APIEndpoint {
    case register(request: RegisterRequest)
    case login(request: LoginRequest)
    case twoFactorLogin(request: TwoFactorLoginRequest)
    case forgotPassword(request: ForgotPasswordRequest)
    case resetPassword(request: ResetPasswordRequest)
    case confirmEmail(request: ConfirmEmailRequest)
    case refreshToken(request: RefreshTokenRequest)
    
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
        case .refreshToken:
            return "/api/auth/refresh-token"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .register, .login, .twoFactorLogin, .forgotPassword, .resetPassword, .confirmEmail, .refreshToken:
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
        case .refreshToken(let request):
            return ["refreshToken": request.refreshToken]
        }
    }
    
    // var headers: [String: String]? {
    //     var baseHeaders = ["Content-Type": "application/json"]
        
    //     if let token = TokenManager.getAccessToken(), 
    //        !(self == .refreshToken),
    //        TokenManager.isAccessTokenValid() {
    //         baseHeaders["Authorization"] = "Bearer \(token)"
    //     }
        
    //     return baseHeaders
    // }
}