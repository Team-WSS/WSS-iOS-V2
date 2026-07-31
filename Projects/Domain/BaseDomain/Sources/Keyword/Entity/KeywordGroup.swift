//
//  KeywordGroup.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct KeywordGroup {
    public let category: KeywordCategory
    public let keywords: [Keyword]

    public init(
        category: KeywordCategory,
        keywords: [Keyword]
    ) {
        self.category = category
        self.keywords = keywords
    }
}
