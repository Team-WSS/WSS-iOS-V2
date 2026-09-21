//
//  FeedCommentTests.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 7/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import CommentDomain
import BaseDomain

@Suite
struct FeedCommentTests {

    // MARK: - Helpers

    private func makeComment(
        isSpoiler: Bool = false,
        isBlocked: Bool = false,
        isHidden: Bool = false
    ) -> FeedComment {
        FeedComment(
            id: CommentID(1),
            user: Author(nickname: "구리스", profileImage: nil),
            createdDate: "방금 전",
            content: "댓글",
            isModified: false,
            isSpoiler: isSpoiler,
            isBlocked: isBlocked,
            isHidden: isHidden
        )
    }

    // MARK: - Visibility

    @Test("아무 플래그도 없으면 그대로 보인다.")
    func visibleByDefault() {
        let comment = makeComment()

        #expect(comment.visibility == .visible)
    }

    @Test("스포일러 댓글은 스포일러 상태로 보인다.")
    func spoilerOnly() {
        let comment = makeComment(isSpoiler: true)

        #expect(comment.visibility == .spoiler)
    }

    @Test("숨김 처리된 댓글은 숨김 상태로 보인다.")
    func hiddenOnly() {
        let comment = makeComment(isHidden: true)

        #expect(comment.visibility == .hidden)
    }

    @Test("차단된 유저의 댓글은 차단 상태로 보인다.")
    func blockedOnly() {
        let comment = makeComment(isBlocked: true)

        #expect(comment.visibility == .blocked)
    }

    @Test("숨김과 스포일러가 겹치면 숨김이 우선한다.")
    func hiddenBeatsSpoiler() {
        let comment = makeComment(isSpoiler: true, isHidden: true)

        #expect(comment.visibility == .hidden)
    }

    @Test("차단과 숨김이 겹치면 차단이 우선한다.")
    func blockedBeatsHidden() {
        let comment = makeComment(isBlocked: true, isHidden: true)

        #expect(comment.visibility == .blocked)
    }

    @Test("차단·숨김·스포일러가 모두 겹치면 차단이 우선한다.")
    func blockedBeatsAll() {
        let comment = makeComment(isSpoiler: true, isBlocked: true, isHidden: true)

        #expect(comment.visibility == .blocked)
    }
}
