//
//  KeywordEndpoint.swift
//  KeywordData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

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
        // TODO: 컨피그 설정 후 baseURL 반영
        URL(string: "https://jsonplaceholder.typicode.com")!
    }
    
    var path: String {
        switch self {
        case .searchKeywords: "/keywords"
        }
    }
    
    var queryItems: [URLQueryItem]? { nil }
    
    var headers: [String : String]? {
        ["Content-Type": "application/json",
         "Authorization": "Bearer " + "dummyAccessToken"]
    }
    
    var body: Data? {
        switch self {
        case .searchKeywords(let request): return request.asRequestBody()
        }
    }
    
    var requireTokenRefresh: Bool { false }
}
