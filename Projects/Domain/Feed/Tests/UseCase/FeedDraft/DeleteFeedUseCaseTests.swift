//
//  DeleteFeedUseCaseTests.swift
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
struct DeleteFeedUseCaseTests {

    @Test("피드를 삭제하면 레포지토리에 id가 전달된다.")
    func deleteFeedPassesID() async throws {
        let mock = MockFeedRepository()
        let usecase = DefaultDeleteFeedUseCase(repository: mock)

        let feedID = FeedID(1)

        try await usecase.execute(feedID: feedID)

        #expect(mock.deletedFeedIDs.contains(feedID))
    }

    @Test("피드 삭제에 실패하면 에러를 던진다.")
    func deleteFeedFailureThrows() async {
        let mock = MockFeedRepository()
        mock.deleteResult = .failure(RepositoryError.notFound)

        let usecase = DefaultDeleteFeedUseCase(repository: mock)

        await #expect(throws: RepositoryError.notFound) {
            try await usecase.execute(feedID: FeedID(1))
        }
    }

}
