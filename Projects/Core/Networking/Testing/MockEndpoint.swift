import Foundation
@testable import Networking

struct MockEndpoint: Endpoint {
    let query: QueryParameters
    let additionalHeaders: [String: String]?
    let body: RequestBody
    let authorization: AuthorizationPolicy

    init(
        query: QueryParameters = .none,
        additionalHeaders: [String: String]? = nil,
        body: RequestBody = .none,
        authorization: AuthorizationPolicy = .requiresToken
    ) {
        self.query = query
        self.additionalHeaders = additionalHeaders
        self.body = body
        self.authorization = authorization
    }

    var method: HTTPMethod { .get }
    var baseURL: URL { URL(string: "https://example.com")! }
    var path: String { "/test" }
}
