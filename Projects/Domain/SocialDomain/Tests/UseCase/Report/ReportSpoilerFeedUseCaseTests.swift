//
//  ReportSpoilerFeedUseCaseTests.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import SocialDomain
import SocialDomainTesting
import BaseDomain

@Suite("ReportSpoilerFeedUseCase")
struct ReportSpoilerFeedUseCaseTests {

    @Test("주어진 피드를 스포일러로 신고할 수 있다")
    func reportsSpoilerFeed() async throws {
        let repo = MockSocialRepository()
        repo.reportSpoilerFeedResult = .success(())

        let sut = DefaultReportSpoilerFeedUseCase(repository: repo)

        let feedID = FeedID(3)
        try await sut.execute(id: feedID)

        #expect(repo.reportSpoilerFeedCallCount == 1)
        #expect(repo.reportedSpoilerFeedIDs == [feedID])
    }

    @Test("피드 스포일러 신고 중 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockSocialRepository()
        repo.reportSpoilerFeedResult = .failure(.serverUnavailable)

        let sut = DefaultReportSpoilerFeedUseCase(repository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.execute(id: FeedID(3))
        }

        #expect(repo.reportSpoilerFeedCallCount == 1)
    }
}
