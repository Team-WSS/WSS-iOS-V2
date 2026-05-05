//
//  LoadSosoFeedsUseCaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import FeedDomain
import FeedDomainTesting
import BaseDomain

@Suite
struct LoadSosoFeedsUseCaseTests {

    @Test("소소 피드를 정상적으로 불러온다")
    func loadSosoFeedsSuccess() async throws {
        let mock = MockFeedRepository()
        let expected = makeSosoFeeds()
        mock.fetchSosoFeedsResult = .success(expected)

        let usecase = DefaultLoadSosoFeedsUseCase(feedRepository: mock)

        let option: SosoFeedOption = .all
        let lastFeedID = FeedID(10)

        let result = try await usecase.execute(option: option, lastFeedID: lastFeedID)

        #expect(result.items == expected.items)
        #expect(mock.fetchedSosoFeeds.last?.0 == option)
        #expect(mock.fetchedSosoFeeds.last?.1 == lastFeedID)
    }

    @Test("소소 피드 조회에 실패하면 에러를 던진다")
    func loadSosoFeedsFailureThrows() async {
        let mock = MockFeedRepository()
        mock.fetchSosoFeedsResult = .failure(RepositoryError.serverUnavailable)

        let usecase = DefaultLoadSosoFeedsUseCase(feedRepository: mock)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await usecase.execute(option: .all, lastFeedID: FeedID(0))
        }
    }
}

extension LoadSosoFeedsUseCaseTests {
    private func makeSosoFeeds() -> Paginated<TotalFeed> {
        Paginated(
            items: [
                TotalFeed(
                    feedId: FeedID(1),
                    createdDate: "",
                    content: "안녕",
                    author: Author(userId: UserID(1003),
                                   nickname: "구리스",
                                   profileImage: ImageWrapper(identifier: "1")
                                  ),
                    likeCount: 1,
                    isLiked: true,
                    commentCount: 1,
                    isSpoiler: false,
                    isModified: false,
                    isPublic: false,
                    imageCount: 1)
            ],
            hasNext: true)
    }
}
