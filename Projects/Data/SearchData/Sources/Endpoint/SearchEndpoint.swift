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
    case getNormalSearchResult(NormalSearchQuery)
    case getDetailSearchResult(DetailSearchQuery)

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
        case .getNormalSearchResult:
            return "/novels"
        case .getDetailSearchResult:
            return "/novels/filtered"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getRecentSearchWords, .getAutoCompletionWords, .getNormalSearchResult, .getDetailSearchResult:
            return .get
        case .deleteRecentSearchWord, .deleteAllRecentSearchWords:
            return .delete
        }
    }

    var query: QueryParameters {
        switch self {
        case .getAutoCompletionWords(let query):
            return .convertible(query)
        case .getNormalSearchResult(let query):
            return .convertible(query)
        case .getDetailSearchResult(let query):
            return .convertible(query)
        case .getRecentSearchWords, .deleteRecentSearchWord, .deleteAllRecentSearchWords:
            return .none
        }
    }

    var additionalHeaders: [String: String]? { nil }

    var body: RequestBody { .none }

    var authorization: AuthorizationPolicy {
        switch self {
        case .getRecentSearchWords,
                .deleteRecentSearchWord,
                .deleteAllRecentSearchWords,
                .getDetailSearchResult:
            return .requireToken
        case .getAutoCompletionWords:
            return .usesTokenIfAvailable
        case .getNormalSearchResult:
            return .withoutToken
        }
    }
}
