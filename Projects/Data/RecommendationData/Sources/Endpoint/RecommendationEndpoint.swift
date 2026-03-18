//
//  RecommendationEndpoint.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/12/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

import Networking

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
        case .getTodayDiscovery: return "/novels/popular"
        case .getTrendingFeeds: return "/feeds/popular"
        case .getInterestFeeds: return "/feeds/interest"
        case .getPreferenceGenreNovels: return "/novels/taste"
        case .sosopickNovels: return "/soso-picks"
        }
    }
    
    var method: HTTPMethod { .get }
    
    var headers: [String : String]? {
        [ "Content-Type": "application/json",
          "Authorization": "Bearer " + NetworkingConfig.testApiKey
        ]
    }
    
    var requireTokenRefresh: Bool { false }
    
    var body: Data? { nil }
    
    var queryItems: [URLQueryItem]? { nil }
}
