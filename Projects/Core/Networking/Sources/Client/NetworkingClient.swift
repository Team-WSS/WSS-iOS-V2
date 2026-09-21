//
//  NetworkingClient.swift
//  Network
//
//  Created by YunhakLee on 10/22/25.
//

import Foundation

public final class NetworkingClient: NetworkingRequestable, Sendable {
    /// 한 요청이 시도할 수 있는 재인증 횟수 상한. 무한 루프를 막는다.
    private static let maxAuthRetries = 2

    private let urlSession: URLSession
    private let logger: NetworkLogging?
    private let tokenStore: SessionTokenStore?
    private let refreshCoordinator: SessionRefreshCoordinator?

    public init(
        urlSession: URLSession = .shared,
        logger: NetworkLogging? = nil,
        tokenStore: SessionTokenStore? = nil,
        authSessionRefresher: AuthSessionRefreshing? = nil
    ) {
        self.urlSession = urlSession
        self.logger = logger
        self.tokenStore = tokenStore
        self.refreshCoordinator = authSessionRefresher.map {
            SessionRefreshCoordinator(refresher: $0, tokenStore: tokenStore)
        }
    }

    public func request(_ endpoint: Endpoint) async throws -> Data {
        try await request(endpoint, remainingAuthRetries: Self.maxAuthRetries)
    }

    private func request(
        _ endpoint: Endpoint,
        remainingAuthRetries: Int
    ) async throws -> Data {
        let authorizationContext = makeAuthorizationContext(for: endpoint)

        do {
            return try await executeRequest(endpoint, authorizationContext: authorizationContext)
        } catch let error as NetworkingError {
            switch error {
            case .responseFailure(let code, _) where code == 401:
                guard authorizationContext.canRefreshSession,
                      remainingAuthRetries > 0 else {
                    throw error
                }
                return try await retryAfterRefreshingSession(
                    for: endpoint,
                    authorizationContext: authorizationContext,
                    remainingAuthRetries: remainingAuthRetries - 1
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
        /// 이번 시도에 실제로 헤더에 담은 토큰. nil이면 미첨부.
        let accessToken: String?
        let canRefreshSession: Bool
    }

    private func makeAuthorizationContext(for endpoint: Endpoint) -> AuthorizationContext {
        switch endpoint.authorization {
        case .requireToken:
            return AuthorizationContext(
                accessToken: currentAccessToken(),
                canRefreshSession: true
            )
        case .withoutToken:
            return AuthorizationContext(
                accessToken: nil,
                canRefreshSession: false
            )
        case .usesTokenIfAvailable:
            let accessToken = currentAccessToken()
            let hasAccessToken = accessToken?.isEmpty == false
            return AuthorizationContext(
                accessToken: hasAccessToken ? accessToken : nil,
                canRefreshSession: hasAccessToken
            )
        }
    }

    /// 세션 종료 판정과 토큰 정리는 `SessionRefreshCoordinator`가 전담한다.
    /// 통신 실패는 세션 종료가 아니므로 에러를 그대로 전파해 토큰을 보존한다.
    private func retryAfterRefreshingSession(
        for endpoint: Endpoint,
        authorizationContext: AuthorizationContext,
        remainingAuthRetries: Int
    ) async throws -> Data {
        guard let refreshCoordinator else {
            throw NetworkingError.requiresReauthentication
        }

        let result = try await refreshCoordinator.refresh(
            usedAccessToken: authorizationContext.accessToken
        )

        switch result {
        case .refreshed, .alreadyRefreshed:
            // 재귀 진입점에서 갱신된 토큰을 다시 읽는다. 카운터가 무한 루프를 막는다.
            return try await request(endpoint, remainingAuthRetries: remainingAuthRetries)
        case .sessionExpired:
            throw NetworkingError.requiresReauthentication
        }
    }

    private func authorizedRequest(
        for endpoint: Endpoint,
        authorizationContext: AuthorizationContext
    ) throws -> URLRequest {
        var request = try endpoint.makeURLRequest()

        guard let accessToken = authorizationContext.accessToken,
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
