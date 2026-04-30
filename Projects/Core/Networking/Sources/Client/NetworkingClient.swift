//
//  NetworkingClient.swift
//  Network
//
//  Created by YunhakLee on 10/22/25.
//

import Foundation

public final class NetworkingClient: NetworkingRequestable {
    private let urlSession: URLSession
    private let logger: NetworkLogging?
    private let tokenStore: SessionTokenStore?
    private let authSessionRefresher: AuthSessionRefreshing?
    
    public init(
        urlSession: URLSession = .shared,
        logger: NetworkLogging? = nil,
        tokenStore: SessionTokenStore? = nil,
        authSessionRefresher: AuthSessionRefreshing? = nil
    ) {
        self.urlSession = urlSession
        self.logger = logger
        self.tokenStore = tokenStore
        self.authSessionRefresher = authSessionRefresher
    }
    
    public func request(_ endpoint: Endpoint) async throws -> Data {
        let authorizationContext = makeAuthorizationContext(for: endpoint)
        
        do {
            return try await executeRequest(endpoint, authorizationContext: authorizationContext)
        } catch let error as NetworkingError {
            switch error {
            case .responseFailure(let code, _) where code == 401:
                guard authorizationContext.canRefreshSession else {
                    throw NetworkingError.requiresReauthentication
                }
                return try await retryAfterRefreshingSession(
                    for: endpoint,
                    authorizationContext: authorizationContext
                )
            case .responseFailure(let code, let body) where code == 404 && body?.code == "USER-006":
                try? tokenStore?.clearTokens()
                throw NetworkingError.requiresReauthentication
            default:
                throw error
            }
        }
    }
    
    private func executeRequest(
        _ endpoint: Endpoint,
        authorizationContext: AuthorizationContext
    ) async throws -> Data {
        let request = try authorizedRequest(
            for: endpoint,
            authorizationContext: authorizationContext
        )
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
    private struct AuthorizationContext {
        let canUseToken: Bool
        let canRefreshSession: Bool
    }
    
    private func makeAuthorizationContext(for endpoint: Endpoint) -> AuthorizationContext {
        switch endpoint.authorization {
        case .requiresToken:
            return AuthorizationContext(canUseToken: true, canRefreshSession: true)
        case .withoutToken:
            return AuthorizationContext(canUseToken: false, canRefreshSession: false)
        case .usesTokenIfAvailable:
            let hasAccessToken = currentAccessToken()?.isEmpty == false
            return AuthorizationContext(
                canUseToken: hasAccessToken,
                canRefreshSession: hasAccessToken
            )
        }
    }
    
    private func retryAfterRefreshingSession(
        for endpoint: Endpoint,
        authorizationContext: AuthorizationContext
    ) async throws -> Data {
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
       
        return try await executeRequest(endpoint, authorizationContext: authorizationContext)
    }
    
    private func authorizedRequest(
        for endpoint: Endpoint,
        authorizationContext: AuthorizationContext
    ) throws -> URLRequest {
        var request = try endpoint.makeURLRequest()

        guard authorizationContext.canUseToken,
              let accessToken = currentAccessToken(),
              accessToken.isEmpty == false else {
            return request
        }

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    private func currentAccessToken() -> String? {
        guard let tokenStore else { return nil }
        return try? tokenStore.accessToken()
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
