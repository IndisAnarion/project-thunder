import Combine
import Foundation

protocol NetworkServiceProtocol {
  func request<T: Decodable>(endpoint: APIEndpoint, responseType: T.Type) -> AnyPublisher<
    T, APIError
  >
  func requestWithoutResponse(endpoint: APIEndpoint) -> AnyPublisher<Void, APIError>
}

class NetworkService: NetworkServiceProtocol {
  private let session: URLSession
  private let authService: AuthServiceProtocol?
  private let isAuthService: Bool

  // Dependency injection ile AuthService döngüsel referansını önlüyoruz
  init(
    session: URLSession = .shared, authService: AuthServiceProtocol? = nil,
    isAuthService: Bool = false
  ) {
    self.session = session
    self.authService = authService
    self.isAuthService = isAuthService
  }

  func request<T: Decodable>(endpoint: APIEndpoint, responseType: T.Type) -> AnyPublisher<
    T, APIError
  > {
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
            throw APIError.unauthorized(String(data: data, encoding: .utf8) ?? "Unauthorized")
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
        // Token refresh mekanizması
        .tryCatch { [weak self] error -> AnyPublisher<T, APIError> in
          guard let self = self,
            !self.isAuthService,  // AuthService itself should not call refresh token to avoid loops
            let apiError = error as? APIError,
            case .unauthorized = apiError,
            let authService = self.createOrGetAuthService()
          else {
            throw error as? APIError ?? APIError.unspecified(error)
          }

          // Token yenileme dene
          return authService.refreshToken()
            .mapError { error in
              return error as? APIError ?? APIError.unspecified(error)
            }
            .flatMap { _ in
              // Token yenilendi, orijinal isteği tekrar gönder
              return self.request(endpoint: endpoint, responseType: responseType)
            }
            .eraseToAnyPublisher()
        }
        .mapError { error in
          return error as? APIError ?? APIError.unspecified(error)
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
            throw APIError.unauthorized(String(data: data, encoding: .utf8) ?? "Unauthorized")
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
        // Token refresh mekanizması
        .tryCatch { [weak self] error -> AnyPublisher<Void, APIError> in
          guard let self = self,
            !self.isAuthService,  // AuthService kendisi refresh token çağırmamalı, döngüyü önlemek için
            let apiError = error as? APIError,
            case .unauthorized = apiError,
            let authService = self.createOrGetAuthService()
          else {
            throw error as? APIError ?? APIError.unspecified(error)
          }

          // Token yenileme dene
          return authService.refreshToken()
            .mapError { error in
              return error as? APIError ?? APIError.unspecified(error)
            }
            .flatMap { _ in
              // Token yenilendi, orijinal isteği tekrar gönder
              return self.requestWithoutResponse(endpoint: endpoint)
            }
            .eraseToAnyPublisher()
        }
        .mapError { error in
          return error as? APIError ?? APIError.unspecified(error)
        }
        .eraseToAnyPublisher()
    } catch {
      return Fail(error: error as? APIError ?? APIError.unspecified(error))
        .eraseToAnyPublisher()
    }
  }

  // AuthService döngüsel bağımlılığını çözmek için yardımcı metot
  private func createOrGetAuthService() -> AuthServiceProtocol? {
    if let authService = authService {
      return authService
    } else {
      // Yeni bir NetworkService oluştur ve isAuthService=true olarak işaretle
      // Böylece sonsuz döngü oluşmasını engellemiş oluruz
      let networkService = NetworkService(session: session, isAuthService: true)
      return AuthService(networkService: networkService)
    }
  }
}
