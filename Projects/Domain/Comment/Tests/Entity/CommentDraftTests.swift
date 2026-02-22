//
//  CommentDraftTests.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import CommentDomain
@testable import BaseDomain

@Suite
struct CommentDraftTests {

    // MARK: - Helpers

    private func makeDraft(content: String = "안녕") -> CommentDraft {
        CommentDraft(content: content)
    }

    //MARK: - Content

    @Test("댓글을 작성할 수 있다.")
    func writeComment() throws {
        var draft = makeDraft()
        let newContent = "새로운 댓글"

        try draft.updateContent(newContent)

        #expect(draft.content == newContent)
    }

    @Test("댓글은 500자를 초과할 수 없다.")
    func contentOverLimitThrows() throws {
        var draft = makeDraft()
        let longText = String(repeating: "a", count: 501)

        #expect(throws: CommentDraft.ValidationError.contentOverLimit) {
            try draft.updateContent(longText)
        }
    }

    @Test("정확히 500자는 작성할 수 있다.")
    func exactlyMaxLengthAllowed() throws {
        var draft = makeDraft()
        let maxText = String(repeating: "a", count: 500)

        try draft.updateContent(maxText)

        #expect(draft.content == maxText)
    }

    @Test("500자 초과 시 기존 작성한 글은 유지한다.")
    func contentPreservedOnOverLimit() throws {
        var draft = makeDraft(content: "원래 댓글")
        let longText = String(repeating: "a", count: 501)

        #expect(throws: CommentDraft.ValidationError.contentOverLimit) {
            try draft.updateContent(longText)
        }

        #expect(draft.content == "원래 댓글")
    }

    @Test("빈 문자열로 수정할 수 없다.")
    func emptyContentThrows() throws {
        var draft = makeDraft()

        #expect(throws: CommentDraft.ValidationError.emptyContent) {
            try draft.updateContent("")
        }
    }

    @Test("빈 문자열 입력 시 기존 작성한 글은 유지한다.")
    func contentPreservedOnEmptyInput() throws {
        var draft = makeDraft(content: "원래 댓글")

        #expect(throws: CommentDraft.ValidationError.emptyContent) {
            try draft.updateContent("")
        }

        #expect(draft.content == "원래 댓글")
    }
}
