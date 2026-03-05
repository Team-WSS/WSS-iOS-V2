//
//  FeedLikeUseCaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain
import FeedDomainTesting
@testable import BaseDomain

@Suite
struct FeedLikeUseCaseTests {

    @Test("좋아요를 클릭하면 레포지토리의 addLike가 호출된다.")
    func likeCallsAddLike() async throws {
        let mockRepository = MockFeedRepository()
        let usecase = DefaultLikeUseCase(feedRepository: mockRepository)
        let feedID = FeedID(1)

        try await usecase.like(feedID: feedID)

        #expect(mockRepository.addedLikeIDs.count == 1)
        #expect(mockRepository.addedLikeIDs.first == feedID)
    }

    @Test("좋아요를 실패하면 에러를 던진다.")
    func likeFailureThrows() async {
        let mockRepository = MockFeedRepository()
        mockRepository.addLikeResult = .failure(RepositoryError.networkUnavailable)

        let usecase = DefaultLikeUseCase(feedRepository: mockRepository)
        let feedID = FeedID(1)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.like(feedID: feedID)
        }
    }

    @Test("좋아요를 클릭하면 레포지토리의 deleteLike가 호출된다.")
    func unlikeCallsDeleteLike() async throws {
        let mockRepository = MockFeedRepository()
        let usecase = DefaultLikeUseCase(feedRepository: mockRepository)
        let feedID = FeedID(2)

        try await usecase.unlike(feedID: feedID)

        #expect(mockRepository.deletedLikeIDs.count == 1)
        #expect(mockRepository.deletedLikeIDs.first == feedID)
    }
}
