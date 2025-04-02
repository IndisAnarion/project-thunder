import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case network(Error)
    case decoding(Error)
    case unspecified(Error)
    case serverError(String)
    case unauthorized(String)
    case notFound
    case badRequest(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("error_invalid_url", comment: "Error when URL is invalid")
        case .invalidResponse:
            return NSLocalizedString("error_invalid_response", comment: "Error when server response is invalid")
        case .invalidData:
            return NSLocalizedString("error_invalid_data", comment: "Error when data from server is invalid")
        case .network(let error):
            return String(format: NSLocalizedString("error_network", comment: "Network error with description"), error.localizedDescription)
        case .decoding(let error):
            return String(format: NSLocalizedString("error_decoding", comment: "Error when decoding data"), error.localizedDescription)
        case .unspecified(let error):
            return String(format: NSLocalizedString("error_unspecified", comment: "Unexpected error"), error.localizedDescription)
        case .serverError(let message):
            return String(format: NSLocalizedString("error_server", comment: "Server error with message"), message)
        case .unauthorized(let message):
            // JSON formatında gelen string'i parse et
            if message.contains("message") {
                do {
                    // JSON string'i data'ya çevir
                    if let data = message.data(using: .utf8) {
                        // JSON'ı decode et
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let errorMessage = json["message"] as? String {
                            return errorMessage
                        }
                    }
                } catch {
                    print("JSON parse error: \(error)")
                }
            }
            // JSON parse edilemezse direkt mesajı döndür
            return message
        case .notFound:
            return NSLocalizedString("error_not_found", comment: "Resource not found error")
        case .badRequest(let message):
            return String(format: NSLocalizedString("error_bad_request", comment: "Bad request error with message"), message)
        }
    }
}