//
//  ReportImproperCommentUseCaseTests.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import SocialDomain
import SocialDomainTesting
import BaseDomain

@Suite("ReportImproperCommentUseCase")
struct ReportImproperCommentUseCaseTests {

    @Test("주어진 댓글을 부적절한 콘텐츠로 신고할 수 있다")
    func reportsImproperComment() async throws {
        let repo = MockSocialRepository()
        repo.reportImproperCommentResult = .success(())

        let sut = DefaultReportImproperCommentUseCase(repository: repo)

        let commentID = CommentID(8)
        try await sut.execute(id: commentID)

        #expect(repo.reportImproperCommentCallCount == 1)
        #expect(repo.reportedImproperCommentIDs == [commentID])
    }

    @Test("댓글 부적절 콘텐츠 신고 중 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockSocialRepository()
        repo.reportImproperCommentResult = .failure(.serverUnavailable)

        let sut = DefaultReportImproperCommentUseCase(repository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.execute(id: CommentID(8))
        }

        #expect(repo.reportImproperCommentCallCount == 1)
    }
}
