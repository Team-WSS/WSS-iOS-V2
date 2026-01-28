//
//  FeedDraftEntityTests.swift
//  Manifests
//
//  Created by Seoyeon Choi on 1/28/26.
//

import Testing
import Foundation
@testable import FeedDomain

@Suite
struct FeedDraftEntityTests {
    
    static func makeDraft(
        content: String = "",
        genre: [NovelGenre] = [],
        isSpoiler: Bool = false,
        isPrivate: Bool = false,
        connectedNovel: ConnectedNovel? = nil,
        attachedImageURLs: [URL] = []) -> FeedDraftEntity {
            FeedDraftEntity(
                content: content,
                genre: genre,
                isSpoiler: isSpoiler,
                isPrivate: isPrivate,
                connectedNovel: connectedNovel,
                attachedImageURLs: attachedImageURLs
            )
        }
    
    @Suite("Content Count")
    struct ContentCountTests {
        @Test
        func contentCount_returnsCorrectLength() {
            let draft = makeDraft(content: "hello")
            
            #expect(draft.contentCount == 5)
        }
        
        @Test
        func remainingContentCount_returnsMaxMinusContentCount() {
            let draft = makeDraft(content: "hello")
            
            #expect(
                draft.remainingContentCount
                == FeedDraftEntity.maxContentCount - 5
            )
        }
    }
    
    @Suite("isSubmittable Rule")
    struct IsSubmittableRuleTests {
        @Test
        func false_whenContentIsEmpty() {
            let draft = makeDraft(
                content: "",
                genre: [.fantasy]
            )
            
            #expect(draft.isSubmittable == false)
        }
        
        @Test
        func false_whenContentIsOnlyWhitespace() {
            let draft = makeDraft(
                content: "   ",
                genre: [.fantasy]
            )
            
            #expect(draft.isSubmittable == false)
        }
        
        @Test
        func false_whenGenreIsEmpty() {
            let draft = makeDraft(
                content: "내용 있음",
                genre: []
            )
            
            #expect(draft.isSubmittable == false)
        }
        
        @Test
        func true_whenContentAndGenreExist() {
            let draft = makeDraft(
                content: "내용 있음",
                genre: [.fantasy]
            )
            
            #expect(draft.isSubmittable == true)
        }
    }
    
    @Suite("State Flags")
    struct StateFlagsTests {
        @Test
        func init_setsSpoilerFlagCorrectly() {
            let draft = makeDraft(isSpoiler: true)
            
            #expect(draft.isSpoiler == true)
        }
        
        @Test
        func init_setsPrivateFlagCorrectly() {
            let draft = makeDraft(isPrivate: true)
            
            #expect(draft.isPrivate == true)
        }
    }
    
    @Suite("Connected Novel")
    struct ConnectedNovelTests {
        @Test
        func init_setsConnectedNovel() {
            let novel = ConnectedNovel(id: 1, title: "Test Novel", genre: .BL)
            let draft = makeDraft(connectedNovel: novel)
            
            #expect(draft.connectedNovel?.id == novel.id)
        }
    }
    
    @Suite("AttachedImage")
    struct AttachedImageTests {
        @Test
        func init_setsAttachedImageURLs() {
            let urls = [
                URL(string: "https://example.com/1.png")!,
                URL(string: "https://example.com/2.png")!
            ]
            
            let draft = makeDraft(attachedImageURLs: urls)
            
            #expect(draft.attachedImageURLs.count == 2)
        }
    }
}
