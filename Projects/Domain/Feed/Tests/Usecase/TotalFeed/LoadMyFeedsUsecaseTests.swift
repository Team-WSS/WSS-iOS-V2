//
//  LoadMyFeedsUsecaseTests.swift
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
struct LoadMyFeedsUsecaseTests {

    @Test("내 피드를 정상적으로 불러온다")
    func loadMyFeedsSuccess() async throws {
        let mock = MockFeedRepository()
        let expected = makeMyFeeds()
        mock.fetchMyFeedsResult = .success(expected)

        let usecase = DefaultLoadMyFeedsUsecase(feedRepository: mock)

        let option: MyFeedOption = makeMyFeedOption()
        let lastFeedID = FeedID(10)

        let result = try await usecase.execute(option: option, lastFeedID: lastFeedID)

        #expect(result.items == expected.items)
        #expect(mock.fetchedMyFeeds.last?.0.genres == option.genres)
        #expect(mock.fetchedMyFeeds.last?.0.visibilityType == option.visibilityType)
        #expect(mock.fetchedMyFeeds.last?.0.sortType == option.sortType)
        #expect(mock.fetchedMyFeeds.last?.1 == lastFeedID)
    }

    @Test("내 피드 조회에 실패하면 에러를 던진다")
    func loadMyFeedsFailureThrows() async {
        let mock = MockFeedRepository()
        mock.fetchMyFeedsResult = .failure(RepositoryError.serverUnavailable)

        let usecase = DefaultLoadMyFeedsUsecase(feedRepository: mock)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await usecase.execute(option: makeMyFeedOption(), lastFeedID: FeedID(0))
        }
    }
}

extension LoadMyFeedsUsecaseTests {
    private func makeMyFeedOption() -> MyFeedOption {
        MyFeedOption(
            genres: [.BL, .drama, .fantasy],
            visibilityType: .publicOnly,
            sortType: .recent
        )
    }
    private func makeMyFeeds() -> Paginated<TotalFeed> {
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
