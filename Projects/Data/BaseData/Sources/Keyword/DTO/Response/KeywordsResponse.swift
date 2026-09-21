//
//  KeywordsResponse.swift
//  BaseData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct KeywordGroupsResponse: Codable {
    public let categories: [KeywordGroupResponse]
    
    public init(categories: [KeywordGroupResponse]) {
        self.categories = categories
    }
}

public struct KeywordGroupResponse: Codable {
    public let categoryName: String
    public let categoryImage: String
    public let keywords: [KeywordResponse]
    
    public init(categoryName: String, categoryImage: String, keywords: [KeywordResponse]) {
        self.categoryName = categoryName
        self.categoryImage = categoryImage
        self.keywords = keywords
    }
}

public struct KeywordResponse: Codable {
    public let keywordId: Int
    public let keywordName: String
    
    public init(keywordId: Int, keywordName: String) {
        self.keywordId = keywordId
        self.keywordName = keywordName
    }
}
