//
//  FeedDraftPolicyTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain

@Suite
struct FeedDraftPolicyTests {
    
    @Test
    func maxContentCount_is2000() {
        #expect(FeedDraftEntity.maxContentCount == 2000)
    }
    
    @Test
    func contentCount_returnsCorrectCount() {
        let entity = FeedDraftEntity(
            content: "12345",
            genre: [.fantasy],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )
        
        #expect(entity.contentCount == 5)
    }
    
    @Test
    func remainingContentCount_calculatesCorrectly() {
        let entity = FeedDraftEntity(
            content: String(repeating: "a", count: 100),
            genre: [.fantasy],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )
        
        #expect(entity.remainingContentCount == 1900)
    }
    
    // MARK: - Submit Validation
    
    @Test
    func isSubmittable_returnsTrue_whenContentIsNotEmpty_andGenreExists() {
        let entity = FeedDraftEntity(
            content: "유효한 피드 내용",
            genre: [.fantasy],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )
        
        #expect(entity.isSubmittable == true)
    }
    
    @Test
    func isSubmittable_returnsFalse_whenContentIsOnlyWhitespace() {
        let entity = FeedDraftEntity(
            content: "   \n",
            genre: [.fantasy],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )
        
        #expect(entity.isSubmittable == false)
    }
    
    @Test
    func isSubmittable_returnsFalse_whenGenreIsEmpty() {
        let entity = FeedDraftEntity(
            content: "내용은 있음",
            genre: [],
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: nil,
            attachedImageURLs: []
        )
        
        #expect(entity.isSubmittable == false)
    }
}
