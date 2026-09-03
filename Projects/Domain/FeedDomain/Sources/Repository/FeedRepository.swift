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
    /// `size`가 nil이면 구현(Data)의 기본 페이지 크기로 조회한다. 재진입 갱신처럼
    /// "보던 개수만큼 한 번에 다시 받기"가 필요한 호출만 명시값을 넘긴다(V1과 같은 계약).
    func fetchNovelFeeds(id: NovelID, lastFeedID: FeedID, size: Int?) async throws(RepositoryError) -> Paginated<TotalFeed>
    
    func addLike(id: FeedID) async throws(RepositoryError)
    func deleteLike(id: FeedID) async throws(RepositoryError)
}
