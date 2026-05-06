//
//  KeywordEndpoint.swift
//  BaseData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

enum KeywordEndpoint: Endpoint {
    case searchKeywords(SearchKeywordQuery)

    var method: HTTPMethod {
        switch self {
        case .searchKeywords: return .get
        }
    }

    var baseURL: URL {
        URL(string: NetworkingConfig.baseURL) ?? URL(string: "")!
    }

    var path: String {
        switch self {
        case .searchKeywords: "/keywords"
        }
    }
    
    var query: QueryParameters {
        switch self {
        case .searchKeywords(let query): return .convertible(query)
        }
    }

    var additionalHeaders: [String: String]? { nil }

    var body: RequestBody { .none }

    var authorization: AuthorizationPolicy { .requireToken }
}
