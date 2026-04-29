//
//  MockEndpoint.swift
//  NetworkingDemo
//
//  Created by YunhakLee on 10/30/25.
//

import Foundation
import Networking

enum MockEndpoint: Endpoint {
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

    var query: QueryParameters { .none }

    var additionalHeaders: [String: String]? { nil }
    
    var body: RequestBody {
        switch self {
        case .createPost(let title, let body):
            return .json(CreatePostRequest(title: title, body: body, userId: 1))
        default:
            return .none
        }
    }

    var authorization: AuthorizationPolicy { .withoutToken }
}

private struct CreatePostRequest: Encodable {
    let title: String
    let body: String
    let userId: Int
}
