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
        // today/trending도 `requireToken`이다(2026-08-31, `usesTokenIfAvailable`에서 전환) —
        // 비로그인 진입이 불가해져 익명 허용의 의미가 없어졌고, 죽은 세션에서 프리페치가
        // 익명 200으로 슬롯을 채우던 세션 전환 함정(#236에서 세션 전환 시 의존성 재조립으로도 방어)도 함께 닫힌다.
        case .getTodayDiscovery, .getTrendingFeeds, .getInterestFeeds, .getPreferenceGenreNovels:
            return .requireToken
        case .sosopickNovels:
            return .withoutToken
        }
    }

}
