import Foundation
import Combine

protocol NetworkServiceProtocol {
    func request<T: Decodable>(endpoint: APIEndpoint, responseType: T.Type) -> AnyPublisher<T, APIError>
    func requestWithoutResponse(endpoint: APIEndpoint) -> AnyPublisher<Void, APIError>
}

class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func request<T: Decodable>(endpoint: APIEndpoint, responseType: T.Type) -> AnyPublisher<T, APIError> {
        do {
            let request = try endpoint.asURLRequest()
            
            return session.dataTaskPublisher(for: request)
                .tryMap { data, response in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    
                    switch httpResponse.statusCode {
                    case 200...299:
                        return data
                    case 400:
                        throw APIError.badRequest(String(data: data, encoding: .utf8) ?? "Bad Request")
                    case 401:
                        throw APIError.unauthorized
                    case 404:
                        throw APIError.notFound
                    case 500...599:
                        throw APIError.serverError(String(data: data, encoding: .utf8) ?? "Server Error")
                    default:
                        throw APIError.invalidResponse
                    }
                }
                .decode(type: T.self, decoder: JSONDecoder())
                .mapError { error in
                    if let apiError = error as? APIError {
                        return apiError
                    } else if error is DecodingError {
                        return APIError.decoding(error)
                    } else {
                        return APIError.unspecified(error)
                    }
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error as? APIError ?? APIError.unspecified(error))
                .eraseToAnyPublisher()
        }
    }
    
    func requestWithoutResponse(endpoint: APIEndpoint) -> AnyPublisher<Void, APIError> {
        do {
            let request = try endpoint.asURLRequest()
            
            return session.dataTaskPublisher(for: request)
                .tryMap { data, response in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    
                    switch httpResponse.statusCode {
                    case 200...299:
                        return
                    case 400:
                        throw APIError.badRequest(String(data: data, encoding: .utf8) ?? "Bad Request")
                    case 401:
                        throw APIError.unauthorized
                    case 404:
                        throw APIError.notFound
                    case 500...599:
                        throw APIError.serverError(String(data: data, encoding: .utf8) ?? "Server Error")
                    default:
                        throw APIError.invalidResponse
                    }
                }
                .mapError { error in
                    if let apiError = error as? APIError {
                        return apiError
                    } else {
                        return APIError.unspecified(error)
                    }
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error as? APIError ?? APIError.unspecified(error))
                .eraseToAnyPublisher()
        }
    }
}