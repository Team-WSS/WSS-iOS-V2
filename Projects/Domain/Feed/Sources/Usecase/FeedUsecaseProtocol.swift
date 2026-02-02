//
//  FeedUsecaseProtocol.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol FeedUsecaseProtocol {
    func createFeed(draft: FeedDraft) async throws
    func editFeed(id: FeedID, draft: FeedDraft) async throws
    func deleteFeed(id: FeedID) async throws
    
    func getFeedDetail(id: FeedID) async throws -> FeedDetail
    
    func getUserFeeds(id: UserID, lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
    func getSosoFeeds(option: SosoFeedOption, lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
    func getMyFeeds(option: MyFeedOption, lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
}
