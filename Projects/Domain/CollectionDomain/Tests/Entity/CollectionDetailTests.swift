//
//  CollectionDetailTests.swift
//  CollectionDomainTests
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain
import CollectionDomain

@Suite("컬렉션 좋아요")
struct CollectionDetailTests {

    // MARK: - 좋아요

    @Test("좋아요하면 좋아요 수가 하나 는다")
    func likingAddsLike() {
        var detail = makeDetail(isLiked: false, likeCount: 10)

        detail.markAsLiked()

        #expect(detail.isLiked == true)
        #expect(detail.likeCount == 11)
    }

    @Test("이미 좋아요했으면 다시 좋아요해도 그대로다")
    func likingAgainChangesNothing() {
        var detail = makeDetail(isLiked: true, likeCount: 10)

        detail.markAsLiked()

        #expect(detail.isLiked == true)
        #expect(detail.likeCount == 10)
    }

    // MARK: - 취소

    @Test("좋아요를 취소하면 좋아요 수가 하나 준다")
    func unlikingRemovesLike() {
        var detail = makeDetail(isLiked: true, likeCount: 10)

        detail.unmarkAsLiked()

        #expect(detail.isLiked == false)
        #expect(detail.likeCount == 9)
    }

    @Test("좋아요하지 않았으면 취소해도 그대로다")
    func unlikingWithoutLikeChangesNothing() {
        var detail = makeDetail(isLiked: false, likeCount: 10)

        detail.unmarkAsLiked()

        #expect(detail.isLiked == false)
        #expect(detail.likeCount == 10)
    }

    @Test("좋아요 수가 0이면 취소해도 0 아래로 내려가지 않는다")
    func unlikingNeverGoesBelowZero() {
        var detail = makeDetail(isLiked: true, likeCount: 0)

        detail.unmarkAsLiked()

        #expect(detail.isLiked == false)
        #expect(detail.likeCount == 0)
    }

    // MARK: - 전환

    @Test("좋아요한 컬렉션에서 좋아요를 전환하면 취소된다")
    func togglingLikeRemovesIt() {
        var detail = makeDetail(isLiked: true, likeCount: 10)

        detail.toggleLike()

        #expect(detail.isLiked == false)
        #expect(detail.likeCount == 9)
    }

    @Test("좋아요하지 않은 컬렉션에서 좋아요를 전환하면 좋아요가 된다")
    func togglingWithoutLikeAddsIt() {
        var detail = makeDetail(isLiked: false, likeCount: 10)

        detail.toggleLike()

        #expect(detail.isLiked == true)
        #expect(detail.likeCount == 11)
    }

    // MARK: - Helpers

    private func makeDetail(isLiked: Bool, likeCount: Int) -> CollectionDetail {
        CollectionDetail(
            id: CollectionID(1),
            name: "컬렉션",
            description: nil,
            owner: Author(userId: UserID(1), nickname: "웹소소", profileImage: nil),
            isMine: false,
            isPrivate: false,
            representativeNovelID: NovelID(1),
            novels: [CollectionNovel(id: NovelID(1), title: "작품", author: "작가", thumbnailImage: nil)],
            likeCount: likeCount,
            isLiked: isLiked
        )
    }
}
