//
//  MyFeedOption.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/2/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct MyFeedOption {
    public let genres: [NovelGenre]
    /// 연결 작품이 없어 장르가 없는(미분류) 내 피드도 포함할지 여부.
    public let includesUncategorized: Bool
    public let visibilityType: VisibilityType
    public let sortType: SortType

    public init(
        genres: [NovelGenre],
        includesUncategorized: Bool,
        visibilityType: VisibilityType,
        sortType: SortType
    ) {
        self.genres = genres
        self.includesUncategorized = includesUncategorized
        self.visibilityType = visibilityType
        self.sortType = sortType
    }
}

public enum VisibilityType {
    case privateOnly
    case publicOnly
    case all
}
