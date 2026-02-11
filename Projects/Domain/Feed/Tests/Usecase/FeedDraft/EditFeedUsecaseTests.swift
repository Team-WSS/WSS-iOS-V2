//
//  EditFeedUsecaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain
@testable import BaseDomain

@Suite
struct EditFeedUsecaseTests {
    
    @Test func `피드를 수정하면 레포지토리에 id와 draft가 전달된다.`() async throws {
        let mock = MockFeedRepository()
        let usecase = DefaultEditFeedUseCase(repository: mock)
        
        let feedID = FeedID(1)
        let draft = makeFeedDraft()
        
        try await usecase.execute(feedID: feedID, editedFeed: draft)
        
        #expect(
            mock.editedFeeds.contains { element in
                element.id == feedID
                && element.draft.attachedImages == draft.attachedImages
                && element.draft.content == draft.content
                && element.draft.genre == draft.genre
            }
        )
    }
    
    @Test func `피드 수정에 실패하면 에러를 던진다.`() async {
        let mock = MockFeedRepository()
        mock.editResult = .failure(RepositoryError.notFound)
        
        let usecase = DefaultEditFeedUseCase(repository: mock)
        
        await #expect(throws: RepositoryError.notFound) {
            try await usecase.execute(feedID: FeedID(1), editedFeed: makeFeedDraft())
        }
    }
}

extension EditFeedUsecaseTests {
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
