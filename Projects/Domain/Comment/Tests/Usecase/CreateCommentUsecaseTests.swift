//
//  CreateCommentUsecaseTests.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import CommentDomain
@testable import BaseDomain

@Suite
struct CreateCommentUsecaseTests {

    @Test func `댓글을 생성하면 레포지토리에 feedID와 draft가 전달된다.`() async throws {
        let mock = MockCommentRepository()
        let usecase = DefaultCreateCommentUsecase(repository: mock)
        let feedID = FeedID(1)
        let draft = makeCommentDraft()

        try await usecase.execute(feedID: feedID, draft)

        #expect(mock.submittedComments.count == 1)
        #expect(mock.submittedComments.first?.feedID == feedID)
        #expect(mock.submittedComments.first?.draft.content == draft.content)
    }

    @Test func `댓글 생성에 실패하면 에러를 던진다.`() async {
        let mock = MockCommentRepository()
        mock.submitResult = .failure(MockError.networkUnavailable)

        let usecase = DefaultCreateCommentUsecase(repository: mock)

        await #expect(throws: MockError.networkUnavailable) {
            try await usecase.execute(feedID: FeedID(1), makeCommentDraft())
        }
    }
}

extension CreateCommentUsecaseTests {
    private func makeCommentDraft() -> CommentDraft {
        CommentDraft(content: "댓글 내용")
    }
}
