//
//  MockEndpoint.swift
//  NetworkingDemo
//
//  Created by YunhakLee on 10/30/25.
//

import Foundation
import Networking

enum MockEndpoint: Endpoint {
    var requireTokenRefresh: Bool { false }
    
    case getPost(id: Int)
    case createPost(title: String, body: String)
    
    var baseURL: URL { URL(string: "https://jsonplaceholder.typicode.com")! }
    
    var path: String {
        switch self {
        case .getPost(let id): return "/posts/\(id)"
        case .createPost: return "/posts"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getPost: return .get
        case .createPost: return .post
        }
    }
    
    var headers: [String : String]? {
        ["Content-Type": "application/json"]
    }
    
    var body: Data? {
        switch self {
        case .createPost(let title, let body):
            let json = ["title": title, "body": body, "userId": 1] as [String: Any]
            return try? JSONSerialization.data(withJSONObject: json)
        default:
            return nil
        }
    }
    
    var queryItems: [URLQueryItem]? { nil }
}
