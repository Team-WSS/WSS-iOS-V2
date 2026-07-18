//
//  NovelEndPoint.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking
import BaseData

enum NovelEndpoint: Endpoint {
    case getUserLibraryNovels(userID: Int, UserLibraryQuery)
    
    case getNovelBasicInfo(novelID: Int)
    case getNovelDetailInfo(novelID: Int)
    case getRegisteredNovelStats(userID: Int)

    case postNovelInterest(novelID: Int)
    case deleteNovelInterest(novelID: Int)
    
    case getNormalSearchResult(NormalSearchQuery)
    case getDetailSearchResult(DetailSearchQuery)
    
    var method: HTTPMethod {
        switch self {
        case .getUserLibraryNovels:     return .get
        case .getNovelBasicInfo:        return .get
        case .getNovelDetailInfo:       return .get
        case .getRegisteredNovelStats:  return .get
        case .postNovelInterest:        return .post
        case .deleteNovelInterest:      return .delete
        case .getNormalSearchResult:    return .get
        case .getDetailSearchResult:    return .get
        }
    }
    
    var baseURL: URL {
        URL(string: NetworkingConfig.baseURL) ?? URL(string: "")!
    }
    
    var path: String {
        switch self {
        case .getUserLibraryNovels(let userID, _):      return "/users/\(userID)/novels"
        case .getNovelBasicInfo(let novelID):           return "/novels/\(novelID)"
        case .getNovelDetailInfo(let novelID):          return "/novels/\(novelID)/info"
        case .getRegisteredNovelStats(let userID):      return "/users/\(userID)/user-novel-stats"
        case .postNovelInterest(let novelID):           return "/novels/\(novelID)/is-interest"
        case .deleteNovelInterest(let novelID):         return "/novels/\(novelID)/is-interest"
        case .getNormalSearchResult:                    return "/novels"
        case .getDetailSearchResult:                    return "/novels/filtered"
        }
    }
    
    var query: QueryParameters {
        switch self {
        case .getUserLibraryNovels(_, let query):   return .convertible(query)
        case .getNormalSearchResult(let query):     return .convertible(query)
        case .getDetailSearchResult(let query):     return .convertible(query)
        default: return .none
        }
    }
    
    var body: RequestBody { return .none }
    
    var authorization: AuthorizationPolicy {
        switch self {
        // 작품 상세는 공개 화면이지만 응답에 유저별 필드(관심·내 평가)가 있다
        // → 로그인 시 토큰을 붙여야 익명 값이 아닌 내 상태가 온다.
        case .getNovelBasicInfo, .getNovelDetailInfo:
            return .usesTokenIfAvailable
        case .getNormalSearchResult:
            return .withoutToken
        default: return .requireToken
        }
    }
    
    var additionalHeaders: [String : String]? { nil }
}
