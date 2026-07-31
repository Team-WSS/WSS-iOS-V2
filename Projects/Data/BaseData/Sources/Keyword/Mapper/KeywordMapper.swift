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
    static func keywordGroups(from dto: KeywordGroupsResponse) throws -> [KeywordGroup] {
        return try dto.categories.map { try keywordGroup(from: $0) }
    }

    static func keywordGroup(from dto: KeywordGroupResponse) throws -> KeywordGroup {
        let category = try keywordCategory(from: dto.categoryName)

        return KeywordGroup(
            category: category,
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

    private static func keywordCategory(from value: String) throws -> KeywordCategory {
        switch value {
        case "세계관":   return .worldview
        case "소재":     return .material
        case "캐릭터":   return .character
        case "관계":     return .relationship
        case "분위기":   return .vibe
        default:         throw MappingError.invalidConversion(type: "KeywordCategory", value: value)
        }
    }
}
