import Foundation
@testable import Networking

struct MockEndpoint: Endpoint {
    let headers: [String: String]?
    let body: RequestBody
    let authorization: AuthorizationPolicy

    init(
        headers: [String: String]? = nil,
        body: RequestBody = .none,
        authorization: AuthorizationPolicy = .required
    ) {
        self.headers = headers
        self.body = body
        self.authorization = authorization
    }

    var method: HTTPMethod { .get }
    var baseURL: URL { URL(string: "https://example.com")! }
    var path: String { "/test" }
    var queryItems: [URLQueryItem]? { nil }
}
