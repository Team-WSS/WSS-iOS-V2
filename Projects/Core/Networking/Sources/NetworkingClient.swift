import Foundation
import Keychain

public final class NetworkingClient: NetworkingRequestable {
    private let urlSession: URLSession
    private let logger: NetworkLogging?
    private let tokenStore: TokenStore?

    public init(
        urlSession: URLSession = .shared,
        logger: NetworkLogging? = nil,
        tokenStore: TokenStore? = nil
    ) {
        self.urlSession = urlSession
        self.logger = logger
        self.tokenStore = tokenStore
    }

    public func request(_ endpoint: Endpoint) async throws -> Data {
        let request = try authorizedRequest(for: endpoint)
        logger?.logRequest(request)
        
        let (data, response) = try await urlSession.data(for: request)
        
        do {
            try validateResponse(data: data, response: response)
            logger?.logResponse(data: data, response: response, error: nil)
            return data
        } catch {
            logger?.logResponse(data: data, response: response, error: error)
            throw error
        }
    }
}

extension NetworkingClient {
    private func authorizedRequest(for endpoint: Endpoint) throws -> URLRequest {
        var request = endpoint.urlRequest

        guard request.value(forHTTPHeaderField: "Authorization") == nil else {
            return request
        }

        guard let accessToken = try tokenStore?.accessToken(), accessToken.isEmpty == false else {
            return request
        }

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func validateResponse(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkingError.invalidURL
        }
        
        switch http.statusCode {
        case 200..<300:
            return
        default:
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw NetworkingError.responseFailure(code: http.statusCode, body: errorResponse)
        }
    }
}
