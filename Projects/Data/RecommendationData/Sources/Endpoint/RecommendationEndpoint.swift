//
//  RecommendationEndpoint.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/12/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

import Networking
import BaseData

enum RecommendationEndpoint: Endpoint {
    case getTodayDiscovery
    case getTrendingFeeds
    case getInterestFeeds
    case getPreferenceGenreNovels
    case sosopickNovels
    
    var baseURL: URL {
        URL(string: NetworkingConfig.baseURL) ?? URL(string: "")!
    }
    
    var path: String {
        switch self {
        case .getTodayDiscovery:            return "/novels/popular"
        case .getTrendingFeeds:             return "/feeds/popular"
        case .getInterestFeeds:             return "/feeds/interest"
        case .getPreferenceGenreNovels:     return "/novels/taste"
        case .sosopickNovels:               return "/soso-picks"
        }
    }
    
    var method: HTTPMethod { .get }

    var query: QueryParameters { .none }

    var additionalHeaders: [String: String]? { nil }

    var body: RequestBody { .none }
    
    var authorization: AuthorizationPolicy {
        switch self {
        case .getInterestFeeds, .getPreferenceGenreNovels:
            return .requiresToken
        case .getTodayDiscovery, .getTrendingFeeds:
            return .usesTokenIfAvailable
        case .sosopickNovels:
            return .withoutToken
        }
    }

}
