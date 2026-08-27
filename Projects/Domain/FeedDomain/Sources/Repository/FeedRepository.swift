//
//  FeedRepository.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol FeedRepository: Sendable {
    func submitFeed(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError)
    func editFeed(id: FeedID, draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError)
    func deleteFeed(id: FeedID) async throws(RepositoryError)
    
    func fetchFeedDetail(id: FeedID) async throws(RepositoryError) -> FeedDetail
    
    func fetchSosoFeeds(option: SosoFeedOption, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed>
    /// 닉네임·프로필 이미지는 응답에 없어(#172) 호출 측이 전달한다 — 유저 피드 조회는 유저 페이지에서만
    /// 일어나므로, 호출 측(UserPageFeature)이 이미 프로필 조회로 값을 갖고 있다는 전제.
    func fetchUserFeeds(id: UserID, nickname: String, profileImage: URL?, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed>
    func fetchMyFeeds(option: MyFeedOption, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed>
    func fetchNovelFeeds(id: NovelID, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed>
    
    func addLike(id: FeedID) async throws(RepositoryError)
    func deleteLike(id: FeedID) async throws(RepositoryError)
}
