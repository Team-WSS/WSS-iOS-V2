//
//  EndPoint.swift
//  Network
//
//  Created by YunhakLee on 10/28/25.
//

import Foundation

public protocol Endpoint {
    var method: HTTPMethod { get }
    var baseURL: URL { get }
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
    
    /// Access토큰 만료 응답인 401이 왔을때 Refresh가 필요한지 여부
    var requireTokenRefresh: Bool { get }
}

public extension Endpoint {
    var urlRequest: URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems

        var request = URLRequest(url: components?.url ?? baseURL)
        request.httpMethod = method.rawValue
        request.httpBody = body
        headers?.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}
