//
//  KeywordResponse.swift
//  KeywordData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct KeywordsResponse: Decodable {
    let categoryName: String
    let categoryImage: String
    let categories: [KeywordResponse]
}

public struct KeywordResponse: Decodable {
    let keywordId: Int
    let keywordName: String
}
