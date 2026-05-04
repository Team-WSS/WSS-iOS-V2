//
//  KeywordsResponse.swift
//  BaseData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct KeywordGroupsResponse: Codable {
    let categories: [KeywordGroupResponse]
}

public struct KeywordGroupResponse: Codable {
    let categoryName: String
    let categoryImage: String
    let keywords: [KeywordResponse]
}

public struct KeywordResponse: Codable {
    let keywordId: Int
    let keywordName: String
}
