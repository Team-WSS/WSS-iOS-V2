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
}

public enum SortType: String {
    case recent = "RECENT"
    case old = "OLD"
}

public enum VisibilityType {
    case privateOnly
    case publicOnly
    case all
}
