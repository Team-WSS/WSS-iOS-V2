//
//  PopularKeywordsResponse.swift
//  BaseData
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct PopularKeywordsResponse: Decodable {
    public let keywords: [PopularKeywordResponse]
    
    public init(keywords: [PopularKeywordResponse]) {
        self.keywords = keywords
    }
}

public struct PopularKeywordResponse: Decodable {
    public let keywordId: Int
    public let keywordName: String
    
    public init(keywordId: Int, keywordName: String) {
        self.keywordId = keywordId
        self.keywordName = keywordName
    }
}
