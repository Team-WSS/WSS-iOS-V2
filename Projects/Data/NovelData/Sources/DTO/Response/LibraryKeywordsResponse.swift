//
//  LibraryKeywordsResponse.swift
//  NovelData
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 서재 등록 키워드 조회(`/users/{userId}/novels/keywords`) 응답.
struct LibraryKeywordsResponse: Decodable {
    public let keywords: [LibraryKeywordResponse]
}

struct LibraryKeywordResponse: Decodable {
    public let keywordId: Int
    public let keywordName: String
}
