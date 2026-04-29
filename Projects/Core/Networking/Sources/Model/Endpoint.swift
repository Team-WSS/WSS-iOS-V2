//
//  EndPoint.swift
//  Network
//
//  Created by YunhakLee on 10/28/25.
//

import Foundation

public enum AuthorizationPolicy {
    case required     // Bearer 토큰 주입 + 401시 refresh 재시도
    case notRequired  // 공개 API (로그인·리이슈 등)
}

public protocol Endpoint {
    var method: HTTPMethod { get }
    var baseURL: URL { get }
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String]? { get }
    var body: RequestBody { get }
    var authorization: AuthorizationPolicy { get }
}

public extension Endpoint {
    var headers: [String: String]? { nil }
    var body: RequestBody { .none }
    var authorization: AuthorizationPolicy { .required }

    func makeURLRequest() throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems

        var request = URLRequest(url: components?.url ?? baseURL)
        request.httpMethod = method.rawValue

        headers?.forEach { key, value in
            guard key.lowercased() != "content-type" else { return }
            request.setValue(value, forHTTPHeaderField: key)
        }

        let encodedBody = try body.encoded()
        request.httpBody = encodedBody.data

        if let contentType = encodedBody.contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}
