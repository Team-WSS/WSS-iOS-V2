import Foundation
@testable import Networking

struct MockEndpoint: Endpoint {
    let headers: [String: String]?
    let authorization: AuthorizationPolicy

    init(
        headers: [String: String]? = nil,
        authorization: AuthorizationPolicy = .required
    ) {
        self.headers = headers
        self.authorization = authorization
    }

    var method: HTTPMethod { .get }
    var baseURL: URL { URL(string: "https://example.com")! }
    var path: String { "/test" }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
}
