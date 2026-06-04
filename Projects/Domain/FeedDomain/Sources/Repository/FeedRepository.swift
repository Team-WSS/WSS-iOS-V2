//
//  FeedRepository.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol FeedRepository {
    func submitFeed(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError)
    func editFeed(id: FeedID, draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError)
    func deleteFeed(id: FeedID) async throws(RepositoryError)
    
    func fetchFeedDetail(id: FeedID) async throws(RepositoryError) -> FeedDetail
    
    func fetchSosoFeeds(option: SosoFeedOption, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed>
    func fetchUserFeeds(id: UserID, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed>
    func fetchMyFeeds(option: MyFeedOption, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed>
    func fetchNovelFeeds(id: NovelID, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed>
    
    func addLike(id: FeedID) async throws(RepositoryError)
    func deleteLike(id: FeedID) async throws(RepositoryError)
}
