//
//  CollectionDetailTests.swift
//  CollectionDomainTests
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
import Foundation

@testable import CollectionDomain
import BaseDomain

@Suite("CollectionDetail")
struct CollectionDetailTests {

    // MARK: - markAsLiked

    @Test("좋아요하지 않은 컬렉션을 좋아요하면 상태가 켜지고 좋아요 수가 늘어난다")
    func markAsLiked() {
        var detail = makeDetail(likeCount: 10, isLiked: false)

        detail.markAsLiked()

        #expect(detail.isLiked)
        #expect(detail.likeCount == 11)
    }

    @Test("이미 좋아요한 컬렉션에 markAsLiked를 호출하면 좋아요 수가 중복으로 늘지 않는다")
    func markAsLikedTwice() {
        var detail = makeDetail(likeCount: 10, isLiked: true)

        detail.markAsLiked()

        #expect(detail.isLiked)
        #expect(detail.likeCount == 10)
    }

    // MARK: - unmarkAsLiked

    @Test("좋아요한 컬렉션을 취소하면 상태가 꺼지고 좋아요 수가 줄어든다")
    func unmarkAsLiked() {
        var detail = makeDetail(likeCount: 10, isLiked: true)

        detail.unmarkAsLiked()

        #expect(detail.isLiked == false)
        #expect(detail.likeCount == 9)
    }

    @Test("좋아요하지 않은 컬렉션에 unmarkAsLiked를 호출하면 좋아요 수가 줄지 않는다")
    func unmarkAsLikedWhenNotLiked() {
        var detail = makeDetail(likeCount: 10, isLiked: false)

        detail.unmarkAsLiked()

        #expect(detail.isLiked == false)
        #expect(detail.likeCount == 10)
    }

    @Test("좋아요 수가 0인 상태에서 취소해도 좋아요 수가 음수로 내려가지 않는다")
    func unmarkAsLikedAtZero() {
        var detail = makeDetail(likeCount: 0, isLiked: true)

        detail.unmarkAsLiked()

        #expect(detail.likeCount == 0)
    }

    // MARK: - toggleLike

    @Test("좋아요하지 않은 컬렉션을 토글하면 좋아요 상태가 된다")
    func toggleLikeOn() {
        var detail = makeDetail(likeCount: 3, isLiked: false)

        detail.toggleLike()

        #expect(detail.isLiked)
        #expect(detail.likeCount == 4)
    }

    @Test("좋아요한 컬렉션을 토글하면 좋아요가 취소된다")
    func toggleLikeOff() {
        var detail = makeDetail(likeCount: 3, isLiked: true)

        detail.toggleLike()

        #expect(detail.isLiked == false)
        #expect(detail.likeCount == 2)
    }

    // MARK: - novelCount

    @Test("작품 수는 담긴 작품 목록의 길이와 같다")
    func novelCountMatchesNovels() {
        let detail = makeDetail(novelCount: 3)

        #expect(detail.novelCount == 3)
    }
}

// MARK: - Helper

private extension CollectionDetailTests {

    func makeDetail(
        novelCount: Int = 1,
        likeCount: Int = 0,
        isLiked: Bool = false
    ) -> CollectionDetail {
        CollectionDetail(
            id: CollectionID(1),
            name: "취향 저격 로판",
            description: nil,
            owner: Author(userId: UserID(1), nickname: "웹소소", profileImage: nil),
            isMine: false,
            isPrivate: false,
            representativeNovelID: NovelID(1),
            novels: (1...max(1, novelCount)).map {
                CollectionNovel(id: NovelID($0), title: "작품", author: "작가", thumbnailImage: nil)
            },
            likeCount: likeCount,
            isLiked: isLiked
        )
    }
}
