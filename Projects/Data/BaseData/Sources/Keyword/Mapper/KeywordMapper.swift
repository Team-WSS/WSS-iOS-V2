//
//  KeywordMapper.swift
//  BaseData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

enum KeywordMapper {
    static func keywordGroups(from dto: KeywordGroupsResponse) -> [KeywordGroup] {
        return dto.categories.map { keywordGroup(from: $0) }
    }

    static func keywordGroup(from dto: KeywordGroupResponse) -> KeywordGroup {
        let groupImageURL = ImageURLResolver.resolve(from: dto.categoryImage)

        return KeywordGroup(
            name: dto.categoryName,
            image: groupImageURL,
            keywords: dto.keywords.map { keyword(from: $0) })
    }

    static func keyword(from dto: KeywordResponse) -> Keyword {
        return Keyword(
            id: KeywordID(dto.keywordId),
            name: dto.keywordName
        )
    }

    static func popularKeywords(from dto: PopularKeywordsResponse) -> PopularKeywords {
        PopularKeywords(keywords: dto.keywords.map { popularKeyword(from: $0) })
    }

    static func popularKeyword(from dto: PopularKeywordResponse) -> Keyword {
        Keyword(
            id: KeywordID(dto.keywordId),
            name: dto.keywordName
        )
    }
}
