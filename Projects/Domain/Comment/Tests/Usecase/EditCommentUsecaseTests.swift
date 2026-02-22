//
//  EditCommentUsecaseTests.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import CommentDomain
import CommentDomainTesting
@testable import BaseDomain

@Suite
struct EditCommentUsecaseTests {

    @Test("댓글을 수정하면 레포지토리에 commentID와 feedID와 draft가 전달된다.")
    func editCommentPassesIDsAndDraft() async throws {
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

    @Test("댓글 수정에 실패하면 에러를 던진다.")
    func editCommentFailureThrows() async {
        let mock = MockCommentRepository()
        mock.editResult = .failure(RepositoryError.networkUnavailable)

        let usecase = DefaultEditCommentUsecase(repository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
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
