//
//  CreateFeedUsecaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain

struct CreateFeedUseCaseTests {

    // MARK: - Invalid Draft

    @Test
    func execute_throwsEmptyContentError_whenContentIsEmpty() async {
        let draft = FeedDraftEntity(
            content: "   ",
            genre: [.fantasy],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )

        let repository = MockFeedRepository()
        let usecase = CreateFeedUseCase(repository: repository)

        await #expect {
            try await usecase.execute(draft: draft)
        } throws: { error in
            guard case CreateFeedError.invalidDraft(let reason) = error else {
                return false
            }
            return reason == .emptyContent
        }
    }

    @Test
    func execute_throwsEmptyGenreError_whenGenreIsEmpty() async {
        let draft = FeedDraftEntity(
            content: "내용 있음",
            genre: [],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )

        let repository = MockFeedRepository()
        let usecase = CreateFeedUseCase(repository: repository)

        await #expect {
            try await usecase.execute(draft: draft)
        } throws: { error in
            guard case CreateFeedError.invalidDraft(let reason) = error else {
                return false
            }
            return reason == .emptyGenre
        }
    }

    // MARK: - Valid Draft

    @Test
    func execute_callsRepository_whenDraftIsValid() async throws {
        let draft = FeedDraftEntity(
            content: "유효한 피드",
            genre: [.fantasy],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )

        let repository = MockFeedRepository()
        let usecase = CreateFeedUseCase(repository: repository)

        try await usecase.execute(draft: draft)

        #expect(repository.submitCalled == true)
    }
}
