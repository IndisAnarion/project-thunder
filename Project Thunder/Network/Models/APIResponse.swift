import Foundation

struct APIResponse<T: Codable>: Codable {
    let status: String
    let message: String?
    let data: T?
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case data
    }
}

// Özel durum: Sadece status ve message içeren yanıt
struct EmptyResponse: Codable {
    // Boş bir Codable model
}