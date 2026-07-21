//
//  UserLibraryV2Query.swift
//  NovelData
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

/// 서재 V2 조회(`/users/{userId}/novels/v2`) 쿼리.
///
/// 서버가 전 필터를 optional로 받으므로, **미적용 필터는 nil로 둬 파라미터 자체를 생략**한다.
/// 빈 배열을 그대로 보내면 `?genres=`(빈 값)로 직렬화돼 서버가 [""] 필터로 오해한다 — nil 필수.
public struct UserLibraryV2Query: QueryItemConvertible {
    public let cursor: String?
    public let size: Int
    public let sortType: String
    public let isInterest: Bool?
    public let readStatuses: [String]?
    public let genres: [String]?
    public let isCompleted: Bool?
    public let ratingMin: Float?
    public let ratingMax: Float?
    public let unratedOnly: Bool?
    public let attractivePoints: [String]?
    public let keywords: [String]?

    public init(
        cursor: String?,
        size: Int,
        sortType: String,
        isInterest: Bool?,
        readStatuses: [String]?,
        genres: [String]?,
        isCompleted: Bool?,
        ratingMin: Float?,
        ratingMax: Float?,
        unratedOnly: Bool?,
        attractivePoints: [String]?,
        keywords: [String]?
    ) {
        self.cursor = cursor
        self.size = size
        self.sortType = sortType
        self.isInterest = isInterest
        self.readStatuses = readStatuses
        self.genres = genres
        self.isCompleted = isCompleted
        self.ratingMin = ratingMin
        self.ratingMax = ratingMax
        self.unratedOnly = unratedOnly
        self.attractivePoints = attractivePoints
        self.keywords = keywords
    }
}
