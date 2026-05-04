//
//  NormalSearchQuery.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

public struct NormalSearchQuery: QueryItemConvertible {
    public let query: String
    public let page: Int
    public let size: Int

    public init(
        query: String,
        page: Int,
        size: Int
    ) {
        self.query = query
        self.page = page
        self.size = size
    }
}
