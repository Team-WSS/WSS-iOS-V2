//
//  FeedDraftTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain
@testable import BaseDomain

@Suite
struct FeedDraftTests {
    
    // MARK: - Helpers
    
    private func makeConnectedNovel() -> ConnectedNovel {
        ConnectedNovel(
            id: NovelID(1),
            title: "괴담에 떨어져도 출근을 해야 하는구나",
            genre: .modernFantasy,
            rating: 4.32
        )
    }
    
    private func makeImageWrapper(id: String) -> ImageWrapper {
        ImageWrapper(identifier: id)
    }
    
    private func makeDraft(
        content: String = "hello",
        genre: [NovelGenre] = [.fantasy],
        isSpoiler: Bool = false,
        isPrivate: Bool = false,
        connectedNovel: ConnectedNovel? = nil,
        attachedImages: [ImageWrapper] = []
    ) -> FeedDraft {
        FeedDraft(
            content: content,
            genre: genre,
            isSpoiler: isSpoiler,
            isPrivate: isPrivate,
            connectedNovel: connectedNovel,
            attachedImages: attachedImages
        )
    }
    
    //MARK: - Content
    
    @Test func `글을 작성할 수 있다.`() throws {
        var mock = makeDraft()
        let newContent = "새로운 내용"
        
        try mock.updateContent(newContent)
        
        #expect(mock.content == newContent)
    }
    
    @Test func `글은 2000자를 초과할 수 없다.`() throws {
        var mock = makeDraft()
        let longText = String(repeating: "a", count: 2001)
        
        #expect(throws: FeedDraft.ValidationError.contentOverLimit(max: 2000)) {
            try mock.updateContent(longText)
        }
    }
    
    @Test func `2000자 초과 시 기존 작성한 글은 유지한다.`() throws {
        var mock = makeDraft(content: "원래 내용")
        let longText = String(repeating: "a", count: 2001)
        
        #expect(throws: FeedDraft.ValidationError.contentOverLimit(max: 2000)) {
            try mock.updateContent(longText)
        }
        
        #expect(mock.content == "원래 내용")
    }
    
    @Test func `남은 글자 수를 확인할 수 있다.`() {
        let mock = makeDraft()
        
        #expect(mock.remainsContentCount() == 2000 - 5)
    }
    
    //MARK: - Genre
    
    @Test func `장르를 추가할 수 있다.`() {
        var mock = makeDraft(genre: [.fantasy])
        
        mock.addGenre(.BL)
        
        #expect(mock.genre == [.fantasy, .BL])
    }
    
    @Test func `선택한 장르를 삭제할 수 있다.`() {
        var mock = makeDraft(genre: [.drama])
        
        mock.removeGenre(.drama)
        
        #expect(mock.genre.isEmpty)
    }
    
    //MARK: - Private
    
    @Test func `비공개로 설정할 수 있다.`() {
        var mock = makeDraft(isPrivate: false)
        
        mock.togglePrivate()
        
        #expect(mock.isPrivate == true)
    }
    
    @Test func `비공개 설정을 해제할 수 있다.`() {
        var mock = makeDraft(isPrivate: true)
        
        mock.togglePrivate()
        
        #expect(mock.isPrivate == false)
    }
    
    //MARK: - Spoiler
    
    @Test func `스포일러성 글로 설정할 수 있다.`() {
        var mock = makeDraft(isSpoiler: false)
        
        mock.toggleSpoiler()
        
        #expect(mock.isSpoiler == true)
    }
    
    @Test func `스포일러 설정을 해제할 수 있다.`() {
        var mock = makeDraft(isSpoiler: true)
        
        mock.toggleSpoiler()
        
        #expect(mock.isSpoiler == false)
    }
    
    //MARK: - Connected Novel
    
    @Test func `글과 관련된 작품을 연결할 수 있다.`() throws {
        var draft = makeDraft()
        
        try draft.setConnectedNovel(makeConnectedNovel())
        
        #expect(draft.connectedNovel != nil)
    }
    
    @Test func `작품은 1개만 연결할 수 있다.`() throws {
        var draft = makeDraft(connectedNovel: makeConnectedNovel())
        
        #expect(throws: FeedDraft.ValidationError.connectedNovelOverLimit) {
            try draft.setConnectedNovel(makeConnectedNovel())
        }
    }
    
    @Test func `연결된 작품을 해제할 수 있다.`() {
        var draft = makeDraft(connectedNovel: makeConnectedNovel())
        
        draft.removeConnectedNovel()
        
        #expect(draft.connectedNovel == nil)
    }
    
    //MARK: - Image
    
    @Test func `글에 이미지를 첨부할 수 있다.`() throws {
        var draft = makeDraft()
        
        try draft.addImage(makeImageWrapper(id: "1"))
        
        #expect(draft.attachedImages.count == 1)
    }
    
    @Test func `이미지는 최대 5장까지 첨부할 수 있다.`() throws {
        let images = Array(repeating: makeImageWrapper(id: "1"), count: 5)
        var draft = makeDraft(attachedImages: images)
        
        #expect(throws: FeedDraft.ValidationError.imageOverLimit(max: 5)) {
            try draft.addImage(makeImageWrapper(id: "2"))
        }
    }
    
    @Test func `첨부된 이미지를 삭제할 수 있다.`() {
        let image = makeImageWrapper(id: "1")
        var draft = makeDraft(attachedImages: [image])
        
        draft.removeImage(image)
        
        #expect(draft.attachedImages.isEmpty)
    }
}
