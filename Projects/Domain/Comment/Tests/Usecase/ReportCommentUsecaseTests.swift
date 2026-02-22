//
//  ReportCommentUsecaseTests.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import CommentDomain
@testable import BaseDomain

@Suite
struct ReportSpoilerCommentUsecaseTests {

    @Test("스포일러 댓글 신고를 성공적으로 요청한다.")
    func reportSpoilerCommentSuccess() async throws {
        let mock = MockCommentRepository()
        mock.reportSpoilerResult = .success(())

        let usecase = DefaultReportCommentUsecase(commentRepository: mock)
        let commentID = CommentID(1)

        try await usecase.reportSpoilerComment(id: commentID)

        #expect(mock.reportedSpoilerCommentID == commentID)
    }

    @Test("스포일러 댓글 신고를 실패하면 에러를 던진다.")
    func reportSpoilerCommentFailureThrows() async {
        let mock = MockCommentRepository()
        mock.reportSpoilerResult = .failure(RepositoryError.networkUnavailable)

        let usecase = DefaultReportCommentUsecase(commentRepository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.reportSpoilerComment(id: CommentID(1))
        }
    }

    @Test("부적절한 댓글 신고를 성공적으로 요청한다.")
    func reportImproperCommentSuccess() async throws {
        let mock = MockCommentRepository()
        mock.reportImproperResult = .success(())

        let usecase = DefaultReportCommentUsecase(commentRepository: mock)
        let commentID = CommentID(1)

        try await usecase.reportImproperComment(id: commentID)

        #expect(mock.reportedImproperCommentID == commentID)
    }

    @Test("부적절한 댓글 신고를 실패하면 에러를 던진다.")
    func reportImproperCommentFailureThrows() async {
        let mock = MockCommentRepository()
        mock.reportImproperResult = .failure(RepositoryError.networkUnavailable)

        let usecase = DefaultReportCommentUsecase(commentRepository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.reportImproperComment(id: CommentID(1))
        }
    }
}
