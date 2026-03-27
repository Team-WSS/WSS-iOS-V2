//
//  UserLibraryQuery.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct UserLibraryQuery: QueryItemConvertible {
    let lastUserNovelId: Int
    let size: Int
    let sortCriteria: String
    let isInterest: Bool
    let readstatues: [String]
    let attractivePoints: [String]
    let novelRating: Float
    let query: String
    let updatedSince: String
}
