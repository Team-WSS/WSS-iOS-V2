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
        let groupImageURL = URL(string: dto.categoryImage)

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
}
