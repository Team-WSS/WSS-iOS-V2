//
//  EditFeedUseCaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import FeedDomain
import FeedDomainTesting
import BaseDomain

@Suite
struct EditFeedUseCaseTests {

    @Test("피드를 수정하면 레포지토리에 id, draft, imageDatas가 전달된다.")
    func editFeedPassesIDAndDraft() async throws {
        let mock = MockFeedRepository()
        let usecase = DefaultEditFeedUseCase(repository: mock)

        let feedID = FeedID(1)
        let draft = makeFeedDraft()
        let imageDatas = [Data("image1".utf8)]

        try await usecase.execute(feedID: feedID, editedFeed: draft, imageDatas: imageDatas)

        #expect(
            mock.editedFeeds.contains { element in
                element.id == feedID
                && element.draft.attachedImages == draft.attachedImages
                && element.draft.content == draft.content
                && element.draft.genre == draft.genre
            }
        )
        #expect(mock.editedImageDatas == [imageDatas])
    }

    @Test("피드 수정에 실패하면 에러를 던진다.")
    func editFeedFailureThrows() async {
        let mock = MockFeedRepository()
        mock.editResult = .failure(RepositoryError.notFound)

        let usecase = DefaultEditFeedUseCase(repository: mock)

        await #expect(throws: RepositoryError.notFound) {
            try await usecase.execute(feedID: FeedID(1), editedFeed: makeFeedDraft(), imageDatas: [])
        }
    }
}

extension EditFeedUseCaseTests {
    private func makeFeedDraft(
        userId: UserID = UserID(1),
        likeCount: Int = 0,
        isLiked: Bool = false
    ) -> FeedDraft {
        FeedDraft(
            content: "안녕",
            genre: [.BL, .drama],
            isSpoiler: true,
            isPrivate: false,
            connectedNovel: nil,
            attachedImages: [])
    }
}
