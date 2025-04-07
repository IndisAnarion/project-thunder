import Foundation
import Security

class TokenManager {
    private static let accessTokenKey = "com.projectthunder.accessToken"
    private static let refreshTokenKey = "com.projectthunder.refreshToken"
    private static let tokenExpirationKey = "com.projectthunder.tokenExpiration"
    
    private static let keychainService = "ProjectThunderTokenService"
    
    // MARK: - Access Token
    
    static func saveAccessToken(_ token: String, expiresIn: Int = 3600) {
        // Keychain'e token'ı kaydet
        saveToKeychain(token, forKey: accessTokenKey)
        
        // Tokenın geçerlilik süresini hesapla ve kaydet
        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        UserDefaults.standard.set(expirationDate.timeIntervalSince1970, forKey: tokenExpirationKey)
    }
    
    static func getAccessToken() -> String? {
        return getFromKeychain(forKey: accessTokenKey)
    }
    
    static func isAccessTokenValid() -> Bool {
        guard getAccessToken() != nil else { return false }
        
        if let expirationTimeInterval = UserDefaults.standard.object(forKey: tokenExpirationKey) as? TimeInterval {
            let expirationDate = Date(timeIntervalSince1970: expirationTimeInterval)
            // Token sona ermesine 5 dakika varsa yenilenmiş olması gerekir
            return Date().addingTimeInterval(5 * 60) < expirationDate
        }
        
        return false
    }
    
    // MARK: - Refresh Token
    
    static func saveRefreshToken(_ token: String) {
        saveToKeychain(token, forKey: refreshTokenKey)
    }
    
    static func getRefreshToken() -> String? {
        return getFromKeychain(forKey: refreshTokenKey)
    }
    
    // MARK: - Clear Tokens
    
    static func clearTokens() {
        deleteFromKeychain(forKey: accessTokenKey)
        deleteFromKeychain(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpirationKey)
    }
    
    // MARK: - Keychain Helpers
    
    private static func saveToKeychain(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Önce varolan kaydı sil
        SecItemDelete(query as CFDictionary)
        
        // Yeni kaydı ekle
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private static func getFromKeychain(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    private static func deleteFromKeychain(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}