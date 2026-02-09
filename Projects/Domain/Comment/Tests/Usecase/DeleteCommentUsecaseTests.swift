//
//  DeleteCommentUsecaseTests.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import CommentDomain
@testable import BaseDomain

@Suite(.tags(.usecase))
struct DeleteCommentUsecaseTests {

    @Test func `댓글을 삭제하면 레포지토리에 commentID와 feedID가 전달된다.`() async throws {
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

    @Test func `댓글 삭제에 실패하면 에러를 던진다.`() async {
        let mock = MockCommentRepository()
        mock.deleteResult = .failure(MockError.notFound)

        let usecase = DefaultDeleteCommentUsecase(repository: mock)

        await #expect(throws: MockError.notFound) {
            try await usecase.execute(commentID: CommentID(1), feedID: FeedID(1))
        }
    }
}
