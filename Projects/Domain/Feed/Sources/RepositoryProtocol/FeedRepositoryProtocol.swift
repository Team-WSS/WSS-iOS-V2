//
//  FeedRepositoryProtocol.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol FeedRepositoryProtocol {
    func submitFeed(_ draft: FeedDraft) async throws
    func editFeed(id: FeedID, draft: FeedDraft) async throws
    func deleteFeed(id: FeedID) async throws
    
    func fetchFeedDetail(id: FeedID) async throws -> FeedDetail
    
    func fetchSosoFeeds(option: SosoFeedOption, lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
    func fetchUserFeeds(id: UserID, lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
    func fetchMyFeeds(option: MyFeedOption, lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
}
