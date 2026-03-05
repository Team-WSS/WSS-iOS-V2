//
//  LoadNovelFeedsUseCaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain
import FeedDomainTesting
@testable import BaseDomain

@Suite
struct LoadNovelFeedsUseCaseTests {

    @Test("작품 피드를 정상적으로 불러온다")
    func loadNovelFeedsSuccess() async throws {
        let mock = MockFeedRepository()
        let expected = makeFeeds()
        mock.fetchNovelFeedsResult = .success(expected)

        let usecase = DefaultLoadNovelFeedsUseCase(feedRepository: mock)
        let novelID = NovelID(10)
        let lastFeedID = FeedID(0)

        let result = try await usecase.execute(novelID: novelID, lastFeedID: lastFeedID)

        #expect(result.items == expected.items)
        #expect(result.hasNext == expected.hasNext)
        #expect(mock.fetchedNovelFeeds.last?.novelID == novelID)
        #expect(mock.fetchedNovelFeeds.last?.lastFeedID == lastFeedID)
    }

    @Test("작품 피드 조회에 실패하면 에러를 던진다")
    func loadNovelFeedsFailureThrows() async {
        let mock = MockFeedRepository()
        mock.fetchNovelFeedsResult = .failure(RepositoryError.serverUnavailable)

        let usecase = DefaultLoadNovelFeedsUseCase(feedRepository: mock)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await usecase.execute(novelID: NovelID(1), lastFeedID: FeedID(0))
        }
    }
}

extension LoadNovelFeedsUseCaseTests {
    private func makeFeeds() -> Paginated<TotalFeed> {
        Paginated(
            items: [
                TotalFeed(
                    feedId: FeedID(1),
                    createdDate: "",
                    content: "이 작품 진짜 재밌어요",
                    author: Author(
                        userId: UserID(1003),
                        nickname: "구리스",
                        profileImage: ImageWrapper(identifier: "1")
                    ),
                    likeCount: 5,
                    isLiked: false,
                    commentCount: 2,
                    isSpoiler: false,
                    isModified: false,
                    isPublic: true,
                    imageCount: 0
                )
            ],
            hasNext: false
        )
    }
}
