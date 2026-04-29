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
        NetworkingClient(
            urlSession: makeSession(),
            tokenStore: MockTokenStore(accessToken: accessToken),
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

    @Test("authorization이 notRequired이면 access token이 있어도 Bearer 헤더를 추가하지 않는다")
    func doesNotAddBearerHeaderWhenAuthorizationNotRequired() async throws {
        MockURLProtocol.requestHandler = nil
        let client = makeClient(accessToken: "access-token")

        MockURLProtocol.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            return try makeResponse(for: request, statusCode: 200)
        }

        _ = try await client.request(MockEndpoint(authorization: .notRequired))
    }

    @Test("body가 없으면 Content-Type과 httpBody를 넣지 않는다")
    func doesNotSetBodyHeadersWhenRequestBodyIsNone() throws {
        let request = try MockEndpoint(
            headers: ["Content-Type": "text/plain"],
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

    @Test("일반 headers는 유지하고 Content-Type은 RequestBody가 결정한다")
    func keepsHeadersAndUsesBodyContentType() throws {
        let request = try MockEndpoint(
            headers: [
                "X-Test": "header",
                "Content-Type": "text/plain"
            ],
            body: .json(SampleRequest(message: "hello"))
        ).makeURLRequest()

        #expect(request.value(forHTTPHeaderField: "X-Test") == "header")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
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

        _ = try await client.request(MockEndpoint(authorization: .required))

        #expect(refresher.refreshCallCount == 1)
        #expect(requestCount.value == 2)
    }

    @Test("401 응답이어도 토큰 갱신이 불가능한 요청이면 재인증 에러를 던진다")
    func throwsReauthenticationErrorWhenUnauthorizedEndpointCannotRefreshToken() async {
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
            _ = try await client.request(MockEndpoint(authorization: .notRequired))
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
    }

    @Test("404와 USER-006 응답이면 재인증 에러를 던진다")
    func throwsReauthenticationErrorWhenUserIsWithdrawn() async throws {
        MockURLProtocol.requestHandler = nil
        let refresher = MockAuthSessionRefresher(behavior: .success(true))
        let client = makeClient(
            accessToken: "access-token",
            authSessionRefresher: refresher
        )
        let body = try makeErrorBody(code: "USER-006")

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 404, data: body)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .required))
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
            _ = try await client.request(MockEndpoint(authorization: .required))
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
            _ = try await client.request(MockEndpoint(authorization: .required))
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
        let client = makeClient(
            accessToken: "access-token",
            authSessionRefresher: refresher
        )

        MockURLProtocol.requestHandler = { request in
            try makeResponse(for: request, statusCode: 401)
        }

        do {
            _ = try await client.request(MockEndpoint(authorization: .required))
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
