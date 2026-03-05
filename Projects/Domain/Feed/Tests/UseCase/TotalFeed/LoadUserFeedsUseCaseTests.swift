//
//  LoadUserFeedsUseCaseTests.swift
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
struct LoadUserFeedsUseCaseTests {

    @Test("타 유저 피드를 정상적으로 불러온다.")
    func loadUserFeedsSuccess() async throws {
        let mock = MockFeedRepository()
        let expected = makeUserFeeds()
        mock.fetchUserFeedsResult = .success(expected)

        let usecase = DefaultLoadUserFeedsUseCase(feedRepository: mock)

        let userID = UserID(100)
        let lastFeedID = FeedID(10)

        let result = try await usecase.execute(userID: userID, lastFeedID: lastFeedID)

        #expect(result.items == expected.items)
        #expect(mock.fetchedUserFeeds.contains { element in
            element.id == userID && element.lastFeedID == lastFeedID
        })
    }

    @Test("타 유저 피드 조회에 실패하면 에러를 던진다.")
    func loadUserFeedsFailureThrows() async {
        let mock = MockFeedRepository()
        mock.fetchUserFeedsResult = .failure(RepositoryError.serverUnavailable)

        let usecase = DefaultLoadUserFeedsUseCase(feedRepository: mock)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await usecase.execute(userID: UserID(100), lastFeedID: FeedID(0))
        }
    }
}

extension LoadUserFeedsUseCaseTests {
    private func makeUserFeeds() -> Paginated<TotalFeed> {
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
