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
/// 예전엔 빈 배열이 `?genres=`(빈 값)로 직렬화돼 서버가 [""] 필터로 오해했기 때문에 nil이 필수였다 —
/// #256부터 `QueryItemConvertible`이 빈 배열도 쿼리에서 생략하므로 그 함정 자체는 사라졌지만,
/// "미적용 = nil" 관례는 의도를 드러내는 표기라 그대로 유지한다.
struct UserLibraryV2Query: QueryItemConvertible {
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
