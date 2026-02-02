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
    
    @Test
    func initializesWithGivenProperties() {

        let content = "테스트 피드 내용"
        let genres: [NovelGenre] = [.fantasy, .romance]
        let isSpoiler = true
        let isPrivate = false
        let connectedNovel: ConnectedNovel? = nil
        let imageURLs: [URL] = [
            URL(string: "https://example.com/image.png")!
        ]
        
        let entity = FeedDraft(
            content: content,
            genre: genres,
            isSpoiler: isSpoiler,
            isPrivate: isPrivate,
            connectedNovel: connectedNovel,
            attachedImageURLs: imageURLs
        )
        
        #expect(entity.content == content)
        #expect(entity.genre == genres)
        #expect(entity.isSpoiler == isSpoiler)
        #expect(entity.isPrivate == isPrivate)
        #expect(entity.connectedNovel == nil)
        #expect(entity.attachedImageURLs == imageURLs)
    }
}
