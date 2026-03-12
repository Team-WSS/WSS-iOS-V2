//
//  CreateCommentUseCaseTests.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import CommentDomain
import CommentDomainTesting
import BaseDomain

@Suite
struct CreateCommentUseCaseTests {

    @Test("댓글을 생성하면 레포지토리에 feedID와 draft가 전달된다.")
    func createCommentPassesFeedIDAndDraft() async throws {
        let mock = MockCommentRepository()
        let usecase = DefaultCreateCommentUseCase(repository: mock)
        let feedID = FeedID(1)
        let draft = makeCommentDraft()

        try await usecase.execute(feedID: feedID, draft)

        #expect(mock.submittedComments.count == 1)
        #expect(mock.submittedComments.first?.feedID == feedID)
        #expect(mock.submittedComments.first?.draft.content == draft.content)
    }

    @Test("댓글 생성에 실패하면 에러를 던진다.")
    func createCommentFailureThrows() async {
        let mock = MockCommentRepository()
        mock.submitResult = .failure(RepositoryError.networkUnavailable)

        let usecase = DefaultCreateCommentUseCase(repository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.execute(feedID: FeedID(1), makeCommentDraft())
        }
    }
}

extension CreateCommentUseCaseTests {
    private func makeCommentDraft() -> CommentDraft {
        CommentDraft(content: "댓글 내용")
    }
}
