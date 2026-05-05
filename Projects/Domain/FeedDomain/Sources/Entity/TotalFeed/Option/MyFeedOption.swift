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
    public let visibilityType: VisibilityType
    public let sortType: SortType
    
    public init(
        genres: [NovelGenre],
        visibilityType: VisibilityType,
        sortType: SortType
    ) {
        self.genres = genres
        self.visibilityType = visibilityType
        self.sortType = sortType
    }
}

public enum VisibilityType {
    case privateOnly
    case publicOnly
    case all
}
