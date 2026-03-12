//
//  LoadCommentsUseCaseTests.swift
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
struct LoadCommentsUseCaseTests {

    @Test("댓글 목록을 성공적으로 불러온다.")
    func loadCommentsSuccess() async throws {
        let mock = MockCommentRepository()
        let expectedComments = [makeComment(id: 1), makeComment(id: 2)]
        mock.fetchCommentsResult = .success(expectedComments)

        let usecase = DefaultLoadCommentsUseCase(repository: mock)
        let feedID = FeedID(1)

        let result = try await usecase.execute(feedID: feedID)

        #expect(result.count == 2)
        #expect(mock.fetchedFeedIDs.contains(feedID))
    }

    @Test("댓글 목록이 비어있어도 정상적으로 반환한다.")
    func loadEmptyCommentsSuccess() async throws {
        let mock = MockCommentRepository()
        mock.fetchCommentsResult = .success([])

        let usecase = DefaultLoadCommentsUseCase(repository: mock)

        let result = try await usecase.execute(feedID: FeedID(1))

        #expect(result.isEmpty)
    }

    @Test("댓글 목록을 불러오다 실패하면 에러를 던진다.")
    func loadCommentsFailureThrows() async {
        let mock = MockCommentRepository()
        mock.fetchCommentsResult = .failure(RepositoryError.networkUnavailable)

        let usecase = DefaultLoadCommentsUseCase(repository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.execute(feedID: FeedID(1))
        }
    }
}

extension LoadCommentsUseCaseTests {
    private func makeComment(id: Int) -> FeedComment {
        FeedComment(
            id: CommentID(id),
            user: Author(
                userId: UserID(1),
                nickname: "테스트유저",
                profileImage: ImageWrapper(identifier: "1")
            ),
            createdDate: "2026-02-09",
            content: "댓글 내용",
            isModified: false,
            isSpoiler: false,
            isBlocked: false,
            isHidden: false
        )
    }
}
