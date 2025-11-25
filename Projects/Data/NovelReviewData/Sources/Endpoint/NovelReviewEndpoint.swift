//
//  NovelReviewEndpoint.swift
//  NovelReviewData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking

enum NovelReviewEndpoint: Endpoint {
    case postReview(PostNovelReviewRequest)
    case getReview(novelId: Int)
    case putReview(novelId: Int, PutNovelReviewRequest)
    case deleteReview(novelId: Int)
    case postInterest(novelId: Int)
    case deleteInterest(novelId: Int)
    
    
    var method: HTTPMethod {
        switch self {
        case .postReview:       return .post
        case .getReview:        return .get
        case .putReview:        return .put
        case .deleteReview:     return .delete
        case .postInterest:     return .post
        case .deleteInterest:   return .delete
        }
    }
    
    var baseURL: URL {
        // TODO: 컨피그 설정 후 baseURL 반영
        URL(string: "https://jsonplaceholder.typicode.com")!
    }
    
    var path: String {
        switch self {
        case .postReview:                   return "/user-novels"
        case .getReview(let novelId):       return "/user-novels/\(novelId)"
        case .putReview(let novelId, _):    return "/user-novels/\(novelId)"
        case .deleteReview(let novelId):    return "/user-novels/\(novelId)"
        case .postInterest(let novelId):    return "/novels/\(novelId)/is-interest"
        case .deleteInterest(let novelId):  return "/novels/\(novelId)/is-interest"
        }
    }
    
    var queryItems: [URLQueryItem]? { nil }
    
    var headers: [String : String]? {
        ["Content-Type": "application/json",
         "Authorization": "Bearer " + "dummyAccessToken"]
    }
    
    var body: Data? {
        switch self {
        case .postReview(let request):    return request.asRequestBody()
        case .putReview(_, let request):  return request.asRequestBody()
        default: return nil
        }
    }
    
    var requireTokenRefresh: Bool { true }
}
