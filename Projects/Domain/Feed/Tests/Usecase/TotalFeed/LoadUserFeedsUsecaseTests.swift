//
//  LoadUserFeedsUsecaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain
@testable import BaseDomain

@Suite
struct LoadUserFeedsUsecaseTests {
    
    func `타 유저 피드를 정상적으로 불러온다.`() async throws {
        let mock = MockFeedRepository()
        let expected = makeUserFeeds()
        mock.fetchUserFeedsResult = .success(expected)
        
        let usecase = DefaultLoadUserFeedsUsecase(feedRepository: mock)
        
        let userID = UserID(100)
        let lastFeedID = FeedID(10)
        
        let result = try await usecase.execute(userID: userID, lastFeedID: lastFeedID)
        
        #expect(result.items == expected.items)
        #expect(mock.fetchedUserFeeds.contains { element in
            element.id == userID && element.lastFeedID == lastFeedID
        })
    }
    
    @Test
    func `타 유저 피드 조회에 실패하면 에러를 던진다.`() async {
        let mock = MockFeedRepository()
        mock.fetchUserFeedsResult = .failure(RepositoryError.serverUnavailable)
        
        let usecase = DefaultLoadUserFeedsUsecase(feedRepository: mock)
        
        await #expect(throws: RepositoryError.serverUnavailable) {
            try await usecase.execute(userID: UserID(100), lastFeedID: FeedID(0))
        }
    }
}

extension LoadUserFeedsUsecaseTests {
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
