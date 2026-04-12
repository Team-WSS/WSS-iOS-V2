//
//  DetailSearchQuery.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

public struct DetailSearchQuery: QueryItemConvertible {
    let genres: [String]
    let isCompleted: Bool
    let novelRating: Float
    let keywordIds: [Int]
    let page: Int
    let size: Int
}
