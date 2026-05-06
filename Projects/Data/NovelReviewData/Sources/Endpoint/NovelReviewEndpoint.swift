//
//  NovelReviewEndpoint.swift
//  NovelReviewData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking
import BaseData

enum NovelReviewEndpoint: Endpoint {
    case postReview(PostNovelReviewRequest)
    case getReview(novelId: Int)
    case putReview(novelId: Int, PutNovelReviewRequest)
    case deleteReview(novelId: Int)
    
    
    var method: HTTPMethod {
        switch self {
        case .postReview:       return .post
        case .getReview:        return .get
        case .putReview:        return .put
        case .deleteReview:     return .delete
        }
    }
    
    var baseURL: URL {
        URL(string: NetworkingConfig.baseURL)!
    }
    
    var path: String {
        switch self {
        case .postReview:                   return "/user-novels"
        case .getReview(let novelId):       return "/user-novels/\(novelId)"
        case .putReview(let novelId, _):    return "/user-novels/\(novelId)"
        case .deleteReview(let novelId):    return "/user-novels/\(novelId)"
        }
    }

    var query: QueryParameters { .none }

    var additionalHeaders: [String: String]? { nil }
    
    var body: RequestBody {
        switch self {
        case .postReview(let request):    return .json(request)
        case .putReview(_, let request):  return .json(request)
        default: return .none
        }
    }

    var authorization: AuthorizationPolicy { .requireToken }
}
