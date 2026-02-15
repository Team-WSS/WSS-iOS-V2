//
//  LoadFeedDetailUsecaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain
@testable import BaseDomain

@Suite
struct LoadFeedDetailUsecaseTests {

    @Test("피드 상세를 성공적으로 불러온다")
    func loadFeedDetailSuccess() async throws {
        let mockRepository = MockFeedRepository()
        let expectedFeed = makeFeedDetail()
        mockRepository.fetchDetailResult = .success(expectedFeed)

        let usecase = DefaultLoadFeedUsecase(feedRepository: mockRepository)
        let feedID = FeedID(1)

        let result = try await usecase.execute(feedID: feedID)

        #expect(result.id == expectedFeed.id)
        #expect(mockRepository.fetchedDetailIDs == feedID)
    }

    @Test("피드 상세를 불러오다 실패하면 에러를 던진다")
    func loadFeedDetailFailureThrows() async {
        let mockRepository = MockFeedRepository()
        mockRepository.fetchDetailResult = .failure(RepositoryError.networkUnavailable)

        let usecase = DefaultLoadFeedUsecase(feedRepository: mockRepository)
        let feedID = FeedID(1)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.execute(feedID: feedID)
        }
    }
}

extension LoadFeedDetailUsecaseTests {
    private func makeFeedDetail(
        userId: UserID = UserID(1),
        likeCount: Int = 0,
        isLiked: Bool = false
    ) -> FeedDetail {
        FeedDetail(
            id: FeedID(1),
            author: Author(
                userId: UserID(1),
                nickname: "구리스",
                profileImage: ImageWrapper(identifier: "1")
            ),
            createdDate: "2026-01-01",
            isModified: false,
            feedContent: "내용",
            feedImageURLs: [],
            connectedNovel: nil,
            likeCount: likeCount,
            isLiked: isLiked,
            commentCount: 0
        )
    }
}
