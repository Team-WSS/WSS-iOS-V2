//
//  EditCommentUsecaseTests.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import CommentDomain
@testable import BaseDomain

@Suite(.tags(.usecase))
struct EditCommentUsecaseTests {

    @Test func `댓글을 수정하면 레포지토리에 commentID와 feedID와 draft가 전달된다.`() async throws {
        let mock = MockCommentRepository()
        let usecase = DefaultEditCommentUsecase(repository: mock)

        let commentID = CommentID(1)
        let feedID = FeedID(1)
        let draft = makeCommentDraft()

        try await usecase.execute(commentID: commentID, feedID: feedID, draft)

        #expect(
            mock.editedComments.contains { element in
                element.id == commentID
                && element.feedID == feedID
                && element.draft.content == draft.content
            }
        )
    }

    @Test func `댓글 수정에 실패하면 에러를 던진다.`() async {
        let mock = MockCommentRepository()
        mock.editResult = .failure(MockError.notFound)

        let usecase = DefaultEditCommentUsecase(repository: mock)

        await #expect(throws: MockError.notFound) {
            try await usecase.execute(
                commentID: CommentID(1),
                feedID: FeedID(1),
                makeCommentDraft()
            )
        }
    }
}

extension EditCommentUsecaseTests {
    private func makeCommentDraft() -> CommentDraft {
        CommentDraft(content: "수정된 댓글")
    }
}
