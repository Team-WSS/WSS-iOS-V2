//
//  MockEndpoint.swift
//  NetworkingDemo
//
//  Created by YunhakLee on 10/30/25.
//

import Foundation
import Networking

enum MockEndpoint: Endpoint {
    var authorization: AuthorizationPolicy { .withoutToken }

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
    
    var body: RequestBody {
        switch self {
        case .createPost(let title, let body):
            return .json(CreatePostRequest(title: title, body: body, userId: 1))
        default:
            return .none
        }
    }
    
    var queryItems: [URLQueryItem]? { nil }
}

private struct CreatePostRequest: Encodable {
    let title: String
    let body: String
    let userId: Int
}
