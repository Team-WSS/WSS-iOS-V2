//
//  DeleteCommentUsecaseTests.swift
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
struct DeleteCommentUsecaseTests {

    @Test("댓글을 삭제하면 레포지토리에 commentID와 feedID가 전달된다.")
    func deleteCommentPassesIDs() async throws {
        let mock = MockCommentRepository()
        let usecase = DefaultDeleteCommentUsecase(repository: mock)

        let commentID = CommentID(1)
        let feedID = FeedID(1)

        try await usecase.execute(commentID: commentID, feedID: feedID)

        #expect(
            mock.deletedComments.contains { element in
                element.id == commentID && element.feedID == feedID
            }
        )
    }

    @Test("댓글 삭제에 실패하면 에러를 던진다.")
    func deleteCommentFailureThrows() async {
        let mock = MockCommentRepository()
        mock.deleteResult = .failure(RepositoryError.networkUnavailable)

        let usecase = DefaultDeleteCommentUsecase(repository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.execute(commentID: CommentID(1), feedID: FeedID(1))
        }
    }
}
