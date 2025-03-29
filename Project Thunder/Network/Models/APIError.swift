import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case network(Error)
    case decoding(Error)
    case unspecified(Error)
    case serverError(String)
    case unauthorized
    case notFound
    case badRequest(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL geçerli değil."
        case .invalidResponse:
            return "Sunucudan geçersiz yanıt alındı."
        case .invalidData:
            return "Sunucudan geçersiz veri alındı."
        case .network(let error):
            return "Ağ hatası: \(error.localizedDescription)"
        case .decoding(let error):
            return "Veri dönüşüm hatası: \(error.localizedDescription)"
        case .unspecified(let error):
            return "Beklenmeyen hata: \(error.localizedDescription)"
        case .serverError(let message):
            return "Sunucu hatası: \(message)"
        case .unauthorized:
            return "Yetkilendirme hatası. Lütfen tekrar giriş yapın."
        case .notFound:
            return "İstenen kaynak bulunamadı."
        case .badRequest(let message):
            return "Geçersiz istek: \(message)"
        }
    }
}