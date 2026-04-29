import Foundation
import Keychain

public final class NetworkingClient: NetworkingRequestable {
    private let urlSession: URLSession
    private let logger: NetworkLogging?
    private let tokenStore: TokenStore?
    private let authSessionRefresher: AuthSessionRefreshing?
    
    public init(
        urlSession: URLSession = .shared,
        logger: NetworkLogging? = nil,
        tokenStore: TokenStore? = nil,
        authSessionRefresher: AuthSessionRefreshing? = nil
    ) {
        self.urlSession = urlSession
        self.logger = logger
        self.tokenStore = tokenStore
        self.authSessionRefresher = authSessionRefresher
    }
    
    public func request(_ endpoint: Endpoint) async throws -> Data {
        do {
            return try await executeRequest(endpoint)
        } catch let error as NetworkingError {
            switch error {
            case .responseFailure(let code, _) where code == 401:
                guard endpoint.authorization == .required else {
                    throw NetworkingError.requiresReauthentication
                }
                return try await retryAfterRefreshingSession(for: endpoint)
            case .responseFailure(let code, let body) where code == 404 && body?.code == "USER-006":
                try? tokenStore?.clearTokens()
                throw NetworkingError.requiresReauthentication
            default:
                throw error
            }
        }
    }
    
    private func executeRequest(_ endpoint: Endpoint) async throws -> Data {
        let request = authorizedRequest(for: endpoint)
        logger?.logRequest(request)

        let (data, response): (Data, URLResponse)
        
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw NetworkingError.unknown(error)
        }

        do {
            try await validateResponse(data: data, response: response)

            logger?.logResponse(data: data, response: response, error: nil)
            return data
        } catch {
            logger?.logResponse(data: data, response: response, error: error)
            throw error
        }
    }
}

extension NetworkingClient {
    private func retryAfterRefreshingSession(for endpoint: Endpoint) async throws -> Data {
        let refreshSuccess: Bool
        do {
            refreshSuccess = try await authSessionRefresher?.refreshSession() ?? false
        } catch {
            try? tokenStore?.clearTokens()
            throw NetworkingError.requiresReauthentication
        }

        guard refreshSuccess else {
            try? tokenStore?.clearTokens()
            throw NetworkingError.requiresReauthentication
        }
       
        return try await executeRequest(endpoint)
    }
    
    private func authorizedRequest(for endpoint: Endpoint) -> URLRequest {
        var request = endpoint.urlRequest

        guard endpoint.authorization == .required,
              let accessToken = try? tokenStore?.accessToken(),
              accessToken.isEmpty == false else {
            return request
        }

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    private func validateResponse(data: Data, response: URLResponse) async throws {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkingError.invalidURL
        }
        
        let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
        
        switch http.statusCode {
        case 200..<300:
            return
        default:
            throw NetworkingError.responseFailure(code: http.statusCode, body: errorResponse)
        }
    }
}
