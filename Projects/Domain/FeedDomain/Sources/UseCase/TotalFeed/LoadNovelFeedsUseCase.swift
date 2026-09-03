//
//  LoadNovelFeedsUseCase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadNovelFeedsUseCase: Sendable {
    /// `size`가 nil이면 기본 페이지 크기. 재진입 갱신은 "보던 개수"를 명시해 한 번에 다시 받는다.
    func execute(novelID: NovelID,
                 lastFeedID: FeedID,
                 size: Int?) async throws(RepositoryError) -> Paginated<TotalFeed>
}

public final class DefaultLoadNovelFeedsUseCase: LoadNovelFeedsUseCase {
    
    private let feedRepository: FeedRepository
    
    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }
    
    public func execute(novelID: NovelID,
                        lastFeedID: FeedID,
                        size: Int?) async throws(RepositoryError) -> Paginated<TotalFeed> {
        try await feedRepository.fetchNovelFeeds(id: novelID, lastFeedID: lastFeedID, size: size)
    }
}
