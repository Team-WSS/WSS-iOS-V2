//
//  FeedDraftTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain

@Suite
struct FeedDraftTests {
    @Test func `글을 작성할 수 있다.`() throws {
        var mock = makeMock()
        let newContent = "새로운 내용"
        
        try mock.updateContent(newContent)
        
        #expect(mock.content == newContent)
    }
    
    @Test func `글은 2000자를 초과할 수 없다.`() throws {
        var mock = makeMock()
        let longText = String(repeating: "a", count: 2001)
        
        #expect(throws: FeedDraft.PolicyError.contentOverLimit) {
            try mock.updateContent(longText)
        }
    }
    
    @Test func `2000자 초과 시 기존 작성한 글은 유지한다.`() throws {
        var mock = makeMock(content: "원래 내용")
        let longText = String(repeating: "a", count: 2001)
        
        #expect(throws: FeedDraft.PolicyError.contentOverLimit) {
            try mock.updateContent(longText)
        }
        
        #expect(mock.content == "원래 내용")
    }
    
    @Test func `장르를 추가할 수 있다.`() {
        var mock = makeMock(genre: [.fantasy])
        
        mock.selectGenre(.BL)
        
        #expect(mock.genre == [.fantasy, .BL])
    }
    
    @Test func `선택한 장르를 삭제할 수 있다.`() {
        var mock = makeMock(genre: [.drama])
        
        mock.deselectGenre(.drama)
        
        #expect(mock.genre.isEmpty)
    }
    
    @Test func `비공개로 설정할 수 있다.`() {
        var mock = makeMock(isPrivate: false)
        
        mock.selectPrivate(true)
        
        #expect(mock.isPrivate == true)
    }
    
    @Test func `스포일러성 글로 설정할 수 있다.`() {
        var mock = makeMock(isSpoiler: false)
        
        mock.selectSpoiler(true)
        
        #expect(mock.isSpoiler == true)
    }
    
    @Test func `내용이 공백이면 제출할 수 없다.`() throws {
        var mock = makeMock(content: "    \n  ")
        
        #expect(throws: FeedDraft.PolicyError.emptyContent) {
            try mock.validateForSubmission()
        }
    }
    
    @Test func `선택한 장르가 없으면 제출할 수 없다.`() throws {
        var mock = makeMock(genre: [])
        
        #expect(throws: FeedDraft.PolicyError.emptyGenre) {
            try mock.validateForSubmission()
        }
    }
    
    @Test func `내용이 있고 선택한 장르가 있으면 제출할 수 있다.`() throws {
        var mock = makeMock(
            content: "정상 내용",
            genre: [.fantasy]
        )
        
        try mock.validateForSubmission()
    }
}

extension FeedDraftTests {
    private func makeMock(
        content: String = "기본 내용",
        genre: [NovelGenre] = [.fantasy],
        isSpoiler: Bool = false,
        isPrivate: Bool = false
    ) -> FeedDraft {
        FeedDraft(
            content: content,
            genre: genre,
            isSpoiler: isSpoiler,
            isPrivate: isPrivate,
            connectedNovel: nil,
            attachedImages: []
        )
    }
}
