//
//  UserLibraryQuery.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

public struct UserLibraryQuery: QueryItemConvertible {
    public let lastUserNovelId: Int
    public let size: Int
    public let sortCriteria: String
    public let isInterest: Bool
    public let readstatues: [String]
    public let attractivePoints: [String]
    public let novelRating: Float
    public let query: String
    public let updatedSince: String

    public init(
        lastUserNovelId: Int,
        size: Int,
        sortCriteria: String,
        isInterest: Bool,
        readstatues: [String],
        attractivePoints: [String],
        novelRating: Float,
        query: String,
        updatedSince: String
    ) {
        self.lastUserNovelId = lastUserNovelId
        self.size = size
        self.sortCriteria = sortCriteria
        self.isInterest = isInterest
        self.readstatues = readstatues
        self.attractivePoints = attractivePoints
        self.novelRating = novelRating
        self.query = query
        self.updatedSince = updatedSince
    }
}
