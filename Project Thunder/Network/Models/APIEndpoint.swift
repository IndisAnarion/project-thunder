import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: String]? { get }
    var bodyParameters: [String: Any]? { get }
    
    func asURLRequest() throws -> URLRequest
}

extension APIEndpoint {
    var baseURL: String {
        // Bu değeri daha sonra konfigürasyon dosyasından alabilirsiniz
        return "http://localhost:5246"
    }
    
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    var queryParameters: [String: String]? {
        return nil
    }
    
    var bodyParameters: [String: Any]? {
        return nil
    }
    
    func asURLRequest() throws -> URLRequest {
        // URL oluşturma
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        urlComponents.path = path
        
        // Query parametrelerini ekle
        if let queryParams = queryParameters, !queryParams.isEmpty {
            urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        // URLRequest oluştur
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Header'ları ekle
        if let headerFields = headers {
            for (key, value) in headerFields {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Body parametrelerini ekle
        if let bodyParams = bodyParameters, !bodyParams.isEmpty {
            if method != .get {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: bodyParams, options: [])
                } catch {
                    throw APIError.invalidData
                }
            }
        }
        
        return request
    }
}