//
//  UserLibraryNovelResponse.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct UserLibraryNovelsResponse: Decodable {
    public let userNovelCount: Int
    public let isLoadable: Bool
    public let userNovels: [UserLibraryNovelResponse]
}

public struct UserLibraryNovelResponse: Decodable {
    public let userNovelId: Int
    public let novelId: Int
    public let title: String
    public let novelImage: String
    public let novelRating: Float
    public let readStatus: String?
    public let isInterest: Bool
    public let userNovelRating: Float
    public let attractivePoints: [String]
    public let startDate: String?
    public let endDate: String?
    public let keywords: [String]
    public let myFeeds: [String]
}
