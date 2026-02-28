//
//  ReportImproperFeedUsecaseTests.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
@testable import SocialDomain
import BaseDomain
@testable import SocialDomainTesting

@Suite("ReportImproperFeedUsecase")
struct ReportImproperFeedUsecaseTests {

    @Test("주어진 피드를 부적절한 콘텐츠로 신고할 수 있다")
    func reportsImproperFeed() async throws {
        let repo = MockSocialRepository()
        repo.reportImproperFeedResult = .success(())

        let sut = DefaultReportImproperFeedUsecase(repository: repo)

        let feedID = FeedID(4)
        try await sut.execute(id: feedID)

        #expect(repo.reportImproperFeedCallCount == 1)
        #expect(repo.reportedImproperFeedIDs == [feedID])
    }

    @Test("피드 부적절 콘텐츠 신고 중 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockSocialRepository()
        repo.reportImproperFeedResult = .failure(.unknown)

        let sut = DefaultReportImproperFeedUsecase(repository: repo)

        await #expect(throws: RepositoryError.unknown) {
            try await sut.execute(id: FeedID(4))
        }

        #expect(repo.reportImproperFeedCallCount == 1)
    }
}
