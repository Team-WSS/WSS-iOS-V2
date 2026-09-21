//
//  FeedAction.swift
//  FeedData
//
//  Created by Lee Wonsun on 5/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

enum FeedAction: String {
    case submitFeed
    case editFeed
    case deleteFeed
    case fetchFeedDetail
    case fetchSosoFeeds
    case fetchUserFeeds
    case fetchMyFeeds
    case fetchNovelFeeds
    case addLike
    case deleteLike
    
    var name: String { self.rawValue }
}
