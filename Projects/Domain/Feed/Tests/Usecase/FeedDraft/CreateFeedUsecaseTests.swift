//
//  CreateFeedUsecaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain
@testable import BaseDomain

@Suite
struct CreateFeedUsecaseTests {
    
    @Test func `피드를 생성하면 레포지토리에 draft가 전달된다.`() async throws {
        let mock = MockFeedRepository()
        let usecase = DefaultCreateFeedUseCase(repository: mock)
        let draft = makeFeedDraft()
        
        try await usecase.execute(draft)
        
        #expect(mock.submittedDrafts.count == 1)
    }
    
    @Test func `피드 생성에 실패하면 에러를 던진다.`() async {
        let mock = MockFeedRepository()
        mock.submitResult = .failure(RepositoryError.notFound)
        
        let usecase = DefaultCreateFeedUseCase(repository: mock)
        
        await #expect(throws: RepositoryError.notFound) {
            try await usecase.execute(makeFeedDraft())
        }
    }
}

extension CreateFeedUsecaseTests {
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
