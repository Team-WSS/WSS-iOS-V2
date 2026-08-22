import Foundation
import Testing
@testable import Networking
@testable import NetworkingTesting

@Suite("NetworkingClient", .serialized)
struct NetworkingClientTests {
    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeClient(
        accessToken: String?,
        authSessionRefresher: AuthSessionRefreshing? = nil
    ) -> NetworkingClient {
        makeClient(
            tokenStore: MockTokenStore(accessToken: accessToken),
            authSessionRefresher: authSessionRefresher
        )
    }

    private func makeClient(
        tokenStore: SessionTokenStore?,
        authSessionRefresher: AuthSessionRefreshing? = nil
    ) -> NetworkingClient {
        NetworkingClient(
            urlSession: makeSession(),
            tokenStore: tokenStore,
            authSessionRefresher: authSessionRefresher
        )
    }

    private func makeResponse(
        for request: URLRequest,
        statusCode: Int,
        data: Data = Data()
    ) throws -> (HTTPURLResponse, Data) {
        guard let url = request.url else {
            throw URLError(.badURL)
        }

        guard let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        ) else {
            throw URLError(.badServerResponse)
        }

        return (response, data)
    }

    private func makeErrorBody(code: String, message: String = "message") throws -> Data {
        try JSONEncoder().encode(
            ErrorResponse(code: code, message: message)
        )
    }

    @Test("요청 시 access token이 있으면 Bearer 헤더를 자동으로 추가한다")
    func addsBearerHeaderWhenAccessTokenExists() async throws {
        MockURLProtocol.requestHandler = nil
        let client = makeClient(accessToken: "access-token")

        MockURLProtocol.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access-token")
            return try makeResponse(for: request, statusCode: 200)
        }

        _ = try await client.request(MockEndpoint())
    }

    @Test("요청 시 access token이 없으면 Bearer 헤더를 자동으로 추가하지 않는다")
    func doesNotAddBearerHeaderWhenAccessTokenDoesNotExist() async throws {
        MockURLProtocol.requestHandler = nil
        let client = makeClient(accessToken: nil)

        MockURLProtocol.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            return try makeResponse(for: request, statusCode: 200)
        }

        _ = try await client.request(MockEndpoint())
    }

    @Test("authorization이 withoutToken이면 access token이 있어도 Bearer 헤더를 추가하지 않는다")
    func doesNotAddBearerHeaderWhenAuthorizationWithoutToken() async throws {
        MockURLProtocol.requestHandler = nil
        let client = makeClient(accessToken: "access-token")

        MockURLProtocol.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            return try makeResponse(for: request, statusCode: 200)
        }

        _ = try await client.request(MockEndpoint(authorization: .withoutToken))
    }

    @Test("authorization이 usesTokenIfAvailable이면 access token이 있을 때 Bearer 헤더를 추가한다")
    func addsBearerHeaderWhenAuthorizationUsesTokenIfAvailableAndAccessTokenExists() async throws {
        MockURLProtocol.requestHandler = nil
        let client = makeClient(accessToken: "access-token")

        MockURLProtocol.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access-token")
            return try makeResponse(for: request, statusCode: 200)
        }

        _ = try await client.request(MockEndpoint(authorization: .usesTokenIfAvailable))
    }

    @Test("authorization이 usesTokenIfAvailable이면 access token이 없을 때 Bearer 헤더를 추가하지 않는다")
    func doesNotAddBearerHeaderWhenAuthorizationUsesTokenIfAvailableAndAccessTokenDoesNotExist() async throws {
        MockURLProtocol.requestHandler = nil
        let client = makeClient(accessToken: nil)

        MockURLProtocol.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            return try makeResponse(for: request, statusCode: 200)
        }

        _ = try await client.request(MockEndpoint(authorization: .usesTokenIfAvailable))
    }

    @Test("body가 없으면 Content-Type과 httpBody를 넣지 않는다")
    func doesNotSetBodyHeadersWhenRequestBodyIsNone() throws {
        let request = try MockEndpoint(
            additionalHeaders: ["Content-Type": "text/plain"],
            body: .none
        ).makeURLRequest()

        #expect(request.httpBody == nil)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == nil)
    }

    @Test("json body는 application/json Content-Type과 함께 인코딩된다")
    func encodesJSONBodyWithContentType() throws {
        let sample = SampleRequest(message: "hello")

        let request = try MockEndpoint(body: .json(sample)).makeURLRequest()
        let body = try #require(request.httpBody)
        let decoded = try JSONDecoder().decode(SampleRequest.self, from: body)

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(decoded == sample)
    }

    @Test("additionalHeaders는 유지하고 Content-Type은 RequestBody가 결정한다")
    func keepsAdditionalHeadersAndUsesBodyContentType() throws {
        let request = try MockEndpoint(
            additionalHeaders: [
                "X-Test": "header",
                "Content-Type": "text/plain"
            ],
            body: .json(SampleRequest(message: "hello"))
        ).makeURLRequest()

        #expect(request.value(forHTTPHeaderField: "X-Test") == "header")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("convertible query는 URLQueryItem으로 변환되어 URL에 반영된다")
    func appliesConvertibleQueryToURL() throws {
        let request = try MockEndpoint(
            query: .convertible(SampleQuery(keyword: "fantasy", page: 1, isAdult: false))
        ).makeURLRequest()
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try #require(components.queryItems)

        #expect(queryItems.contains(URLQueryItem(name: "keyword", value: "fantasy")))
        #expect(queryItems.contains(URLQueryItem(name: "page", value: "1")))
        #expect(queryItems.contains(URLQueryItem(name: "isAdult", value: "false")))
    }

    @Test("custom query는 전달한 URLQueryItem을 그대로 URL에 반영한다")
    func appliesCustomQueryToURL() throws {
        let request = try MockEndpoint(
            query: .custom([
                URLQueryItem(name: "ids", value: "1"),
                URLQueryItem(name: "ids", value: "2")
            ])
        ).makeURLRequest()
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try #require(components.queryItems)

        #expect(queryItems == [
            URLQueryItem(name: "ids", value: "1"),
            URLQueryItem(name: "ids", value: "2")
        ])
    }

    @Test("multipart body는 각 part와 boundary를 포함해 인코딩된다")
    func encodesMultipartBodyWithPartsAndBoundary() throws {
        let formData = MultipartFormData(
            boundary: "test-boundary",
            parts: [
                .json(keyName: "request", value: SampleRequest(message: "hello")),
                .text(keyName: "description", value: "sample"),
                .imageData(keyName: "images", data: Data("image".utf8)),
                .imageData(
                    keyName: "profileImage",
                    data: Data("png".utf8),
                    contentType: .png,
                    fileName: "profile.png"
                ),
                .data(
                    keyName: "document",
                    data: Data("pdf".utf8),
                    contentType: .custom(headerValue: "application/pdf", fileExtension: "pdf")
                )
            ]
        )

        let request = try MockEndpoint(body: .multipart(formData)).makeURLRequest()
        let body = try #require(request.httpBody)
        let bodyString = try #require(String(data: body, encoding: .utf8))

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "multipart/form-data; boundary=test-boundary")
        #expect(bodyString.contains("--test-boundary\r\n"))
        #expect(bodyString.contains("Content-Disposition: form-data; name=\"request\""))
        #expect(bodyString.contains("Content-Type: application/json"))
        #expect(bodyString.contains("\"message\":\"hello\""))
        #expect(bodyString.contains("Content-Disposition: form-data; name=\"description\""))
        #expect(bodyString.contains("Content-Type: text/plain"))
        #expect(bodyString.contains("Content-Disposition: form-data; name=\"images\"; filename=\"image.jpeg\""))
        #expect(bodyString.contains("Content-Type: image/jpeg"))
        #expect(bodyString.contains("Content-Disposition: form-data; name=\"profileImage\"; filename=\"profile.png\""))
        #expect(bodyString.contains("Content-Type: image/png"))
        #expect(bodyString.contains("Content-Disposition: form-data; name=\"document\"; filename=\"file.pdf\""))
        #expect(bodyString.contains("Content-Type: application/pdf"))
        #expect(bodyString.hasSuffix("--test-boundary--\r\n"))
    }

    @Test("body 인코딩 실패 시 requestEncodingFailed를 던진다")
    func throwsRequestEncodingFailedWhenBodyEncodingFails() {
        do {
            _ = try MockEndpoint(body: .json(FailingRequest())).makeURLRequest()
            Issue.record("requestEncodingFailed expected")
        } catch let error as NetworkingError {
            guard case .requestEncodingFailed = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test("401 응답이고 토큰 갱신이 가능하면 refresh 후 한 번 재시도한다")
    func retriesOnceAfterRefreshingSessionOnUnauthorizedResponse() async throws {
        MockURLProtocol.requestHandler = nil
        let refresher = MockAuthSessionRefresher(behavior: .success(true))
        let client = makeClient(
            accessToken: "access-token",
            authSessionRefresher: refresher
        )
        let requestCount = LockedCounter()

        MockURLProtocol.requestHandler = { request in
            let count = requestCount.increment()

            if count == 1 {
                return try makeResponse(for: request, statusCode: 401)
            }

            return try makeResponse(for: request, statusCode: 200)
        }

        _ = try await client.request(MockEndpoint(authorization: .requireToken))

        #expect(refresher.refreshCallCount == 1)
        #expect(requestCount.value == 2)
    }

    @Test("usesTokenIfAvailable 요청에서 access token이 있으면 401 응답 시 refresh 후 한 번 재시도한다")
    func retriesOnceAfterRefreshingSessionForUsesTokenIfAvailableWithAccessToken() async throws {
        MockURLProtocol.requestHandler = nil
        let refresher = MockAuthSessionRefresher(behavior: .success(true))
        let client = makeClient(
            accessToken: "access-token",
            authSessionRefresher: refresher
        )
        let requestCount = LockedCounter()

        MockURLProtocol.requestHandler = { request in
            let count = requestCount.increment()

            if count == 1 {
                return try makeResponse(for: request, statusCode: 401)
            }

            return try makeResponse(for: request, statusCode: 200)
        }

        _ = try await client.request(MockEndpoint(authorization: .usesTokenIfAvailable))

        #expect(refresher.refreshCallCount == 1)
        #expect(requestCount.value == 2)
    }

    @Test("usesTokenIfAvailable 요청에서 access token이 없으면 401 응답 시 원래 에러를 유지한다")
    func keepsUnauthorizedErrorForUsesTokenIfAvailableWithoutAccessToken() async {
        MockURLProtocol.requestHandler = nil
        let refresher = MockAuthSessionRefresher(behavior: .success(true))
        let client = makeClient(
            accessToken: nil,
            authSessionRefresher: refresher
        )

        MockURLProtocol.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            return try makeResponse(for: request, statusCode: 401)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .usesTokenIfAvailable))
            Issue.record("responseFailure expected")
        } catch let error as NetworkingError {
            guard case .responseFailure(let code, _) = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
            #expect(code == 401)
        } catch {
            Issue.record("unexpected error: \(error)")
        }

        #expect(refresher.refreshCallCount == 0)
    }

    @Test("401 응답이어도 토큰 갱신이 불가능한 요청이면 원래 에러를 유지한다")
    func keepsUnauthorizedErrorWhenEndpointCannotRefreshToken() async {
        MockURLProtocol.requestHandler = nil
        let refresher = MockAuthSessionRefresher(behavior: .success(true))
        let client = makeClient(
            accessToken: "access-token",
            authSessionRefresher: refresher
        )

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 401)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .withoutToken))
            Issue.record("responseFailure expected")
        } catch let error as NetworkingError {
            guard case .responseFailure(let code, _) = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
            #expect(code == 401)
        } catch {
            Issue.record("unexpected error: \(error)")
        }

        #expect(refresher.refreshCallCount == 0)
    }

    @Test("404와 USER-006 응답이면 재인증 에러를 던진다")
    func throwsReauthenticationErrorWhenUserIsWithdrawn() async throws {
        MockURLProtocol.requestHandler = nil
        let refresher = MockAuthSessionRefresher(behavior: .success(true))
        let tokenStore = MockTokenStore(accessToken: "access-token")
        let client = makeClient(
            tokenStore: tokenStore,
            authSessionRefresher: refresher
        )
        let body = try makeErrorBody(code: "USER-006")

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 404, data: body)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .requireToken))
            Issue.record("requiresReauthentication expected")
        } catch let error as NetworkingError {
            guard case .requiresReauthentication = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("unexpected error: \(error)")
        }

        #expect(refresher.refreshCallCount == 0)
        #expect(tokenStore.clearTokensCallCount == 1)
    }

    @Test("404여도 USER-006이 아니면 원래 responseFailure를 유지한다")
    func keepsResponseFailureWhenNotWithdrawnUserError() async throws {
        MockURLProtocol.requestHandler = nil
        let client = makeClient(accessToken: "access-token")
        let body = try makeErrorBody(code: "BOOK-404")

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 404, data: body)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .requireToken))
            Issue.record("responseFailure expected")
        } catch let error as NetworkingError {
            guard case .responseFailure(let code, let errorBody) = error else {
                Issue.record("unexpected error: \(error)")
                return
            }

            #expect(code == 404)
            #expect(errorBody?.code == "BOOK-404")
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test("401과 404가 아닌 응답이면 원래 responseFailure를 유지한다")
    func keepsResponseFailureForUnhandledStatusCode() async {
        MockURLProtocol.requestHandler = nil
        let client = makeClient(accessToken: "access-token")

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 500)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .requireToken))
            Issue.record("responseFailure expected")
        } catch let error as NetworkingError {
            guard case .responseFailure(let code, _) = error else {
                Issue.record("unexpected error: \(error)")
                return
            }

            #expect(code == 500)
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test("refresh 실패 시 재인증 에러를 던진다")
    func throwsReauthenticationErrorWhenRefreshFails() async {
        MockURLProtocol.requestHandler = nil
        let refresher = MockAuthSessionRefresher(behavior: .success(false))
        let tokenStore = MockTokenStore(accessToken: "access-token")
        let client = makeClient(
            tokenStore: tokenStore,
            authSessionRefresher: refresher
        )

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 401)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .requireToken))
            Issue.record("requiresReauthentication expected")
        } catch let error as NetworkingError {
            guard case .requiresReauthentication = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("unexpected error: \(error)")
        }

        #expect(refresher.refreshCallCount == 1)
        #expect(tokenStore.clearTokensCallCount == 1)
    }

    @Test("통신 실패로 refresh가 던지면 토큰을 보존하고 원래 에러를 전파한다")
    func keepsTokensWhenRefreshFailsWithTransportError() async {
        MockURLProtocol.requestHandler = nil
        let refresher = MockAuthSessionRefresher(
            behavior: .failure(NetworkingError.unknown(URLError(.cannotConnectToHost)))
        )
        let tokenStore = MockTokenStore(accessToken: "access-token")
        let client = makeClient(
            tokenStore: tokenStore,
            authSessionRefresher: refresher
        )

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 401)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .requireToken))
            Issue.record("unknown error expected")
        } catch let error as NetworkingError {
            guard case .unknown = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("unexpected error: \(error)")
        }

        #expect(refresher.refreshCallCount == 1)
        #expect(tokenStore.clearTokensCallCount == 0)
    }

    @Test("refresh가 401로 거절되면 세션을 종료하고 토큰을 지운다")
    func clearsTokensWhenRefreshIsRejectedWithUnauthorized() async {
        MockURLProtocol.requestHandler = nil
        let refresher = MockAuthSessionRefresher(
            behavior: .failure(NetworkingError.responseFailure(
                code: 401,
                body: ErrorResponse(code: "AUTH-001", message: "유효하지 않은 토큰입니다.")
            ))
        )
        let tokenStore = MockTokenStore(accessToken: "access-token")
        let client = makeClient(
            tokenStore: tokenStore,
            authSessionRefresher: refresher
        )

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 401)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .requireToken))
            Issue.record("requiresReauthentication expected")
        } catch let error as NetworkingError {
            guard case .requiresReauthentication = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("unexpected error: \(error)")
        }

        #expect(refresher.refreshCallCount == 1)
        #expect(tokenStore.clearTokensCallCount == 1)
    }

    /// 404·5xx는 "이 토큰으로는 갱신이 안 된다"까지만 알려준다 → 재인증으로 보내되,
    /// 토큰까지 지우면 서버가 복구돼도 세션을 되살릴 수 없으므로 남긴다.
    /// 재발급 실패를 원 요청의 404로 흘려보내면 화면이 "없는 리소스"로 오해한다.
    @Test("refresh가 404로 실패하면 토큰은 보존한 채 재인증을 요구한다")
    func requiresReauthenticationButKeepsTokensWhenRefreshFailsWithNonAuthStatus() async {
        MockURLProtocol.requestHandler = nil
        let refresher = MockAuthSessionRefresher(
            behavior: .failure(NetworkingError.responseFailure(code: 404, body: nil))
        )
        let tokenStore = MockTokenStore(accessToken: "access-token")
        let client = makeClient(
            tokenStore: tokenStore,
            authSessionRefresher: refresher
        )

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 401)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .requireToken))
            Issue.record("requiresReauthentication expected")
        } catch let error as NetworkingError {
            guard case .requiresReauthentication = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("unexpected error: \(error)")
        }

        #expect(tokenStore.clearTokensCallCount == 0)
    }

    /// 200을 받아도 스키마가 깨져 파싱에 실패하면 **저장된 토큰은 낡은 그대로**다.
    /// 이걸 데이터 오류로 흘려보내면 화면이 로그인 유도를 못 해 같은 실패만 반복한다.
    @Test("refresh 응답 파싱에 실패하면 토큰은 보존한 채 재인증을 요구한다")
    func requiresReauthenticationButKeepsTokensWhenRefreshResponseCannotBeDecoded() async {
        MockURLProtocol.requestHandler = nil
        let refresher = MockAuthSessionRefresher(behavior: .failure(NetworkingError.decoding))
        let tokenStore = MockTokenStore(accessToken: "access-token")
        let client = makeClient(
            tokenStore: tokenStore,
            authSessionRefresher: refresher
        )

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 401)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .requireToken))
            Issue.record("requiresReauthentication expected")
        } catch let error as NetworkingError {
            guard case .requiresReauthentication = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("unexpected error: \(error)")
        }

        #expect(tokenStore.clearTokensCallCount == 0)
    }

    @Test("동시에 401을 받아도 토큰 재발급은 한 번만 실행된다")
    func refreshesOnlyOnceForConcurrentUnauthorizedResponses() async throws {
        MockURLProtocol.requestHandler = nil
        let tokenStore = MockTokenStore(accessToken: "old-token")
        let refresher = MockAuthSessionRefresher {
            // 재발급이 겹칠 시간을 만든다. 없으면 순차 실행되어 버그가 있어도 통과한다.
            try await Task.sleep(nanoseconds: 50_000_000)
            tokenStore.update(accessToken: "new-token")
            return true
        }
        let client = makeClient(
            tokenStore: tokenStore,
            authSessionRefresher: refresher
        )

        let unauthorizedCount = LockedCounter()

        // 순번이 아니라 "어떤 토큰으로 왔는가"로 판정한다. 동시 요청에선 순번이 비결정적이다.
        MockURLProtocol.requestHandler = { request in
            let isRenewed = request.value(forHTTPHeaderField: "Authorization") == "Bearer new-token"

            if isRenewed == false {
                _ = unauthorizedCount.increment()
            }

            return try makeResponse(for: request, statusCode: isRenewed ? 200 : 401)
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    _ = try await client.request(MockEndpoint(authorization: .requireToken))
                }
            }
            try await group.waitForAll()
        }

        // ⚠️ **겹침이 실제로 일어났는지**를 함께 못 박는다 — 이 단언이 없으면 요청들이 순차로 밀려
        // 갱신 뒤에 도착해도(=겹치지 않아도) 재발급 1회라 통과해버린다(가짜 green).
        // `== 5`로 조이지 않는 이유는 그쪽이 스케줄링에 기대는 flaky 조건이 되기 때문 —
        // 부하로 한 요청만 늦게 출발해도 구현이 멀쩡한데 빨간불이 뜬다.
        #expect(unauthorizedCount.value >= 2)

        // 여기서 못 박는 건 **결과**다 — "동시 401 N건이 재발급 1회로 합쳐진다". 그걸 막은 게
        // coalescing인지 토큰 세대 비교인지는 구분하지 않는다(둘 다 있어야 하는 방어이고,
        // 세대 비교는 바로 아래 테스트가 따로 검증한다). 둘을 완전히 분리하려면 재발급이 토큰을
        // 갱신하지 않는 더블이 필요한데, 그러면 재시도 상한과 얽혀 다시 타이밍에 기대게 된다.
        #expect(refresher.refreshCallCount == 1)
        #expect(tokenStore.clearTokensCallCount == 0)
    }

    @Test("이미 갱신된 뒤 도착한 401은 재발급 없이 새 토큰으로 재시도한다")
    func retriesWithoutRefreshingWhenTokenWasAlreadyRenewed() async throws {
        MockURLProtocol.requestHandler = nil
        let tokenStore = MockTokenStore(accessToken: "old-token")
        let refresher = MockAuthSessionRefresher(behavior: .success(true))
        let client = makeClient(
            tokenStore: tokenStore,
            authSessionRefresher: refresher
        )

        MockURLProtocol.requestHandler = { request in
            guard request.value(forHTTPHeaderField: "Authorization") == "Bearer old-token" else {
                return try makeResponse(for: request, statusCode: 200)
            }
            // 내 요청이 나간 뒤 다른 요청이 갱신을 끝낸 상황
            tokenStore.update(accessToken: "new-token")
            return try makeResponse(for: request, statusCode: 401)
        }

        _ = try await client.request(MockEndpoint(authorization: .requireToken))

        #expect(refresher.refreshCallCount == 0)
        #expect(tokenStore.clearTokensCallCount == 0)
    }

    @Test("재발급 후에도 401이면 두 번까지만 재발급하고 401을 유지한다")
    func stopsRefreshingAfterReachingMaxAuthRetries() async {
        MockURLProtocol.requestHandler = nil
        let tokenStore = MockTokenStore(accessToken: "access-token")
        let issuedTokenCount = LockedCounter()
        let refresher = MockAuthSessionRefresher {
            tokenStore.update(accessToken: "token-\(issuedTokenCount.increment())")
            return true
        }
        let client = makeClient(
            tokenStore: tokenStore,
            authSessionRefresher: refresher
        )

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 401)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .requireToken))
            Issue.record("responseFailure expected")
        } catch let error as NetworkingError {
            guard case .responseFailure(let code, _) = error else {
                Issue.record("unexpected error: \(error)")
                return
            }

            #expect(code == 401)
        } catch {
            Issue.record("unexpected error: \(error)")
        }

        #expect(refresher.refreshCallCount == 2)
    }
}

private final class LockedCounter {
    private let lock = NSLock()
    private var storage = 0

    var value: Int {
        lock.withLock { storage }
    }

    func increment() -> Int {
        lock.withLock {
            storage += 1
            return storage
        }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}

private struct SampleRequest: Codable, Equatable {
    let message: String
}

private struct SampleQuery: QueryItemConvertible {
    let keyword: String
    let page: Int
    let isAdult: Bool
}

private struct FailingRequest: Encodable {
    func encode(to encoder: Encoder) throws {
        throw EncodingError.invalidValue(
            "failure",
            EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Forced encoding failure"
            )
        )
    }
}
