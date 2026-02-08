//
//  FeedLikeUsecaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain

@Suite(.tags(.usecase))
struct FeedLikeUsecaseTests {
    
    @Test func `좋아요를 클릭하면 레포지토리의 addLike가 호출된다.`() async throws {
        let mockRepository = MockFeedRepository()
        let usecase = DefaultLikeUsecase(feedRepository: mockRepository)
        let feedID = FeedID(1)
        
        try await usecase.like(feedID: feedID)
        
        #expect(mockRepository.addedLikeIDs.count == 1)
        #expect(mockRepository.addedLikeIDs.first == feedID)
    }
    
    @Test func `좋아요를 실패하면 에러를 던진다.`() async {
        let mockRepository = MockFeedRepository()
        mockRepository.addLikeResult = .failure(RepositoryError.networkUnavailable)
        
        let usecase = DefaultLikeUsecase(feedRepository: mockRepository)
        let feedID = FeedID(1)
        
        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.like(feedID: feedID)
        }
    }
    
    @Test func `좋아요를 클릭하면 레포지토리의 deleteLike가 호출된다.`() async throws {
        let mockRepository = MockFeedRepository()
        let usecase = DefaultLikeUsecase(feedRepository: mockRepository)
        let feedID = FeedID(2)
        
        try await usecase.unlike(feedID: feedID)
        
        #expect(mockRepository.deletedLikeIDs.count == 1)
        #expect(mockRepository.deletedLikeIDs.first == feedID)
    }
}
