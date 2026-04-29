import Foundation
@testable import Networking

struct MockEndpoint: Endpoint {
    let headers: [String: String]?
    let shouldRequireTokenRefresh: Bool

    init(
        headers: [String: String]? = nil,
        requireTokenRefresh: Bool = false
    ) {
        self.headers = headers
        self.shouldRequireTokenRefresh = requireTokenRefresh
    }

    var method: HTTPMethod { .get }
    var baseURL: URL { URL(string: "https://example.com")! }
    var path: String { "/test" }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var requireTokenRefresh: Bool { shouldRequireTokenRefresh }
}
