//
//  SearchEndpoint.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import Foundation

import Networking
import BaseData

enum SearchEndpoint: Endpoint {
    case getRecentSearchWords
    case deleteRecentSearchWord(id: Int)
    case deleteAllRecentSearchWords
    case getAutoCompletionWords(SearchAutoCompletionQuery)
    
    var baseURL: URL {
        URL(string: NetworkingConfig.baseURL) ?? URL(string: "")!
    }

    var path: String {
        switch self {
        case .getRecentSearchWords, .deleteAllRecentSearchWords:
            return "/novels/recent-searches"
        case .deleteRecentSearchWord(let id):
            return "/novels/recent-searches/\(id)"
        case .getAutoCompletionWords:
            return "/novels/autocomplete"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getRecentSearchWords, .getAutoCompletionWords:
            return .get
        case .deleteRecentSearchWord, .deleteAllRecentSearchWords:
            return .delete
        }
    }

    var query: QueryParameters {
        switch self {
        case .getAutoCompletionWords(let query):
            return .convertible(query)
        case .getRecentSearchWords, .deleteRecentSearchWord, .deleteAllRecentSearchWords:
            return .none
        }
    }

    var additionalHeaders: [String: String]? { nil }

    var body: RequestBody { .none }

    var authorization: AuthorizationPolicy {
        switch self {
        case .getRecentSearchWords, .deleteRecentSearchWord, .deleteAllRecentSearchWords:
            return .requireToken
        case .getAutoCompletionWords:
            return .usesTokenIfAvailable
        }
    }
}
