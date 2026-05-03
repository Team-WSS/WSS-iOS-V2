//
//  KeywordGroup.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct KeywordGroup {
    public let name: String
    public let image: URL?
    public let keywords: [Keyword]

    public init(
        name: String,
        image: URL?,
        keywords: [Keyword]
    ) {
        self.name = name
        self.image = image
        self.keywords = keywords
    }
}
