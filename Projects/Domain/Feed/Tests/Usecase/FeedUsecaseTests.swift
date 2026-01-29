//
//  FeedUsecaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain

@Suite
struct FeedUsecaseTests {
    @Test
    func createFeed_callsRepository_whenDraftIsValid() async throws {
        let repository = MockFeedRepository()
        let usecase = FeedUsecase(repository: repository)
        
        let validDraft = FeedDraftEntity(
            content: "정상 내용",
            genre: [.fantasy],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )
        
        try await usecase.createFeed(draft: validDraft)
        
        #expect(repository.submitCalled == true)
    }
    
    @Test
    func createFeed_throwsError_andDoesNotCallRepository_whenDraftIsInvalid() async {
        let repository = MockFeedRepository()
        let usecase = FeedUsecase(repository: repository)
        
        let invalidDraft = FeedDraftEntity(
            content: "   ",
            genre: [],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )
        
        await #expect(throws: CreateFeedError.self) {
            try await usecase.createFeed(draft: invalidDraft)
        }
        
        #expect(repository.submitCalled == false)
    }
    
    @Test
    func editFeed_callsRepository_whenDraftIsValid() async throws {
        let repository = MockFeedRepository()
        let usecase = FeedUsecase(repository: repository)
        
        let feedId = FeedID(1)
        let validDraft = FeedDraftEntity(
            content: "수정된 내용",
            genre: [.fantasy],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )
        
        try await usecase.editFeed(id: feedId, draft: validDraft)
        
        #expect(repository.editCalled == true)
        #expect(repository.receivedFeedID == feedId)
    }
    
    @Test
    func editFeed_throwsError_andDoesNotCallRepository_whenDraftIsInvalid() async {
        let repository = MockFeedRepository()
        let usecase = FeedUsecase(repository: repository)
        
        let feedId = FeedID(1)
        let invalidDraft = FeedDraftEntity(
            content: "   ",
            genre: [],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )
        
        await #expect(throws: CreateFeedError.self) {
            try await usecase.editFeed(id: feedId, draft: invalidDraft)
        }
        
        #expect(repository.editCalled == false)
    }
    
    @Test
    func deleteFeed_callsRepository_withFeedId() async throws {
        let repository = MockFeedRepository()
        let usecase = FeedUsecase(repository: repository)
        
        let feedId = FeedID(99)
        
        try await usecase.deleteFeed(id: feedId)
        
        #expect(repository.deleteCalled == true)
        #expect(repository.receivedFeedID == feedId)
    }
}
