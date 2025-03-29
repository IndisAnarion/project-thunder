import Foundation

struct AuthResponse: Codable {
    let status: String
    let message: String?
    let accessToken: String?
    let refreshToken: String?
    let user: UserInfo?
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case accessToken
        case refreshToken
        case user
    }
}

struct UserInfo: Codable {
    let email: String
    let displayName: String?
    let phoneNumber: String?
    let profilePictureUrl: String?
    let company: String?
}

struct RegisterRequest: Codable {
    let displayName: String
    let email: String
    let password: String
    let phoneNumber: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct TwoFactorLoginRequest: Codable {
    let email: String
    let password: String
    let twoFactorCode: String
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ResetPasswordRequest: Codable {
    let userId: String
    let token: String
    let newPassword: String
    let confirmPassword: String
}

struct ConfirmEmailRequest: Codable {
    let userId: String
    let token: String
}