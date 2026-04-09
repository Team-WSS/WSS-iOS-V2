//
//  Tests.swift
//  Networking
//
//  Created by Seoyeon Choi on 11/10/25.
//

import XCTest
import Keychain
@testable import Networking

final class NetworkingClientTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        MockURLProtocol.requestHandler = nil
    }

    func testRequestAddsBearerAccessTokenByDefault() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = NetworkingClient(
            urlSession: session,
            tokenStore: MockTokenStore(accessToken: "access-token")
        )

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        _ = try await client.request(MockEndpoint())
    }

    func testRequestKeepsExistingAuthorizationHeader() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = NetworkingClient(
            urlSession: session,
            tokenStore: MockTokenStore(accessToken: "access-token")
        )

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Custom token")

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        _ = try await client.request(MockEndpoint(headers: ["Authorization": "Custom token"]))
    }
}

private struct MockEndpoint: Endpoint {
    let headers: [String: String]?

    init(headers: [String: String]? = nil) {
        self.headers = headers
    }

    var method: HTTPMethod { .get }
    var baseURL: URL { URL(string: "https://example.com")! }
    var path: String { "/test" }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var requireTokenRefresh: Bool { false }
}

private final class MockTokenStore: TokenStore {
    private let storedAccessToken: String?

    init(accessToken: String?) {
        self.storedAccessToken = accessToken
    }

    func saveAccessToken(_ token: String) throws { }
    func saveRefreshToken(_ token: String) throws { }
    func accessToken() throws -> String? { storedAccessToken }
    func refreshToken() throws -> String? { nil }
    func clearTokens() throws { }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}
