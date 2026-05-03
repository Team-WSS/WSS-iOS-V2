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
    case searchKeywords(SearchKeywordRequest)

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

    var queryItems: [URLQueryItem]? {
        switch self {
        case .searchKeywords(let request): return request.asQueryItems()
        }
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json",
         "Authorization": "Bearer " + NetworkingConfig.testApiKey]
    }

    var body: Data? { nil }

    var requireTokenRefresh: Bool { false }
}
