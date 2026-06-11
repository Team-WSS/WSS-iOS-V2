//
//  NovelBasicResponse.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct NovelBasicResponse: Decodable {
    public let userNovelId: Int?
    public let novelTitle: String
    public let novelImage: String
    public let novelGenres: [String]
    public let novelGenreImage: String
    public let isNovelCompleted: Bool
    public let author: String
    public let interestCount: Int
    public let novelRating: Float
    public let novelRatingCount: Int
    public let feedCount: Int
    public let userNovelRating: Float
    public let readStatus: String?
    public let startDate: String?
    public let endDate: String?
    public let isUserNovelInterest: Bool
}
