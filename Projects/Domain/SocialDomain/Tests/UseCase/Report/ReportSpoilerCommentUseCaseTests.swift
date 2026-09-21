//
//  ReportSpoilerCommentUseCaseTests.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import SocialDomain
import SocialDomainTesting
import BaseDomain

@Suite("ReportSpoilerCommentUseCase")
struct ReportSpoilerCommentUseCaseTests {

    @Test("주어진 댓글을 스포일러로 신고할 수 있다")
    func reportsSpoilerComment() async throws {
        let repo = MockSocialRepository()
        repo.reportSpoilerCommentResult = .success(())

        let sut = DefaultReportSpoilerCommentUseCase(repository: repo)

        let feedID = FeedID(1)
        let commentID = CommentID(7)
        try await sut.execute(feedID: feedID, commentID: commentID)

        #expect(repo.reportSpoilerCommentCallCount == 1)
        #expect(repo.reportedSpoilerCommentFeedIDs == [feedID])
        #expect(repo.reportedSpoilerCommentIDs == [commentID])
    }

    @Test("댓글 스포일러 신고 중 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockSocialRepository()
        repo.reportSpoilerCommentResult = .failure(.networkUnavailable)

        let sut = DefaultReportSpoilerCommentUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await sut.execute(feedID: FeedID(1), commentID: CommentID(7))
        }

        #expect(repo.reportSpoilerCommentCallCount == 1)
    }
}
