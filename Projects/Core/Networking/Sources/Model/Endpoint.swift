//
//  EndPoint.swift
//  Network
//
//  Created by YunhakLee on 10/28/25.
//

import Foundation

public enum AuthorizationPolicy {
    case requireToken          // Bearer 토큰 주입 + 401시 refresh 재시도
    case withoutToken           // 공개 API (로그인·리이슈 등)
    case usesTokenIfAvailable   // 토큰이 있으면 주입 + 401시 refresh 재시도
}

public protocol Endpoint {
    var method: HTTPMethod { get }
    var baseURL: URL { get }
    var path: String { get }
    var query: QueryParameters { get }
    var additionalHeaders: [String: String]? { get }
    var body: RequestBody { get }
    var authorization: AuthorizationPolicy { get }
}

public extension Endpoint {
    func makeURLRequest() throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = query.queryItems

        var request = URLRequest(url: components?.url ?? baseURL)
        request.httpMethod = method.rawValue

        additionalHeaders?.forEach { key, value in
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
