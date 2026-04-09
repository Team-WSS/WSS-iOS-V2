//
//  CommentEndpoint.swift
//  CommentData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

enum CommentEndpoint: Endpoint {
    case getComments(feedId: Int)
    case postComment(feedId: Int, CommentRequest)
    case putComment(feedId: Int, commentId: Int, CommentRequest)
    case deleteComment(feedId: Int, commentId: Int)
    
    
    var method: HTTPMethod {
        switch self {
        case .getComments:      return .get
        case .postComment:      return .post
        case .putComment:       return .put
        case .deleteComment:    return .delete
        }
    }
    
    var baseURL: URL {
        // TODO: 컨피그 설정 후 baseURL 반영
        URL(string: "https://jsonplaceholder.typicode.com")!
    }
    
    var path: String {
        switch self {
        case .getComments(let feedId):                          return "/feeds/\(feedId)/comments"
        case .postComment(let feedId, _):                       return "/feeds/\(feedId)/comments"
        case .putComment(let feedId, let commentId, _):         return "/feeds/\(feedId)/comments/\(commentId)"
        case .deleteComment(let feedId, let commentId):         return "/feeds/\(feedId)/comments/\(commentId)"
        }
    }
    
    var queryItems: [URLQueryItem]? { nil }
    
    var headers: [String : String]? {
        ["Content-Type": "application/json",
         "Authorization": "Bearer " + "dummyAccessToken"]
    }
    
    var body: Data? {
        switch self {
        case .postComment(_ , let request):     return request.asRequestBody()
        case .putComment(_, _, let request):    return request.asRequestBody()
        default: return nil
        }
    }
    
    var requireTokenRefresh: Bool { true }
}
