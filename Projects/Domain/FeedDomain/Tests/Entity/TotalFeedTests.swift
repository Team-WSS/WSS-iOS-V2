//
//  TotalFeedTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/2/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import FeedDomain
import FeedDomainTesting
import BaseDomain

@Suite
struct TotalFeedTests {

    @Test("좋아요를 누를 수 있다.")
    func addLike() throws {
        var mock = makeMock(likeCount: 3, isLiked: false)

        try mock.toggleLike()

        #expect(mock.likeCount == 4)
        #expect(mock.isLiked == true)
    }

    @Test("좋아요를 삭제할 수 있다.")
    func removeLike() throws {
        var mock = makeMock(likeCount: 3, isLiked: true)

        try mock.toggleLike()

        #expect(mock.likeCount == 2)
        #expect(mock.isLiked == false)
    }

    @Test("좋아요 수는 음수가 될 수 없다.")
    func likeCountCannotBeNegative() {
        var mock = makeMock(likeCount: 0, isLiked: true)

        #expect(throws: TotalFeed.PolicyError.negativeLikeCount) {
            try mock.toggleLike()
        }
    }

    @Test("재조회 병합은 좋아요 상태만 로컬을 따르고 나머지는 서버 값을 유지한다")
    func preservingLikeStateKeepsOnlyLikeFieldsFromLocal() throws {
        // 서버 응답: 좋아요는 토글 이전 스냅샷(3, 안 누름), 본문·댓글수·연결작품·썸네일은 최신.
        let server = TotalFeed(
            feedId: FeedID(1),
            createdDate: "2026-02-06",
            content: "수정된 최신 본문",
            author: Author(userId: UserID(10), nickname: "작성자", profileImage: nil),
            likeCount: 3,
            isLiked: false,
            commentCount: 7,
            connectedNovel: makeMockConnectedNovel(),
            isSpoiler: false,
            isModified: true,
            isPublic: true,
            isMyFeed: false,
            thumbnailImageURL: URL(string: "https://example.com/updated-thumb.jpg"),
            imageCount: 0
        )
        // 로컬: 낙관 토글 반영(4, 누름), 본문·댓글수는 옛 값.
        var local = makeMock(likeCount: 3, isLiked: false)
        try local.toggleLike()

        let merged = server.preservingLikeState(of: local)

        #expect(merged.isLiked == true)
        #expect(merged.likeCount == 4)
        #expect(merged.content == "수정된 최신 본문")
        #expect(merged.commentCount == 7)
        #expect(merged.isModified == true)
        // 기본값(nil)이 있는 두 파라미터는 병합 구현에서 빠뜨려도 컴파일이 통과하므로,
        // 서버 항목에 non-nil 값을 심어 서버 값이 그대로 유지되는지 명시 검증한다(빠지면 nil이 되어 실패).
        #expect(merged.connectedNovel == server.connectedNovel)
        #expect(merged.thumbnailImageURL == server.thumbnailImageURL)
    }
}

extension TotalFeedTests {
    private func makeMockConnectedNovel() -> ConnectedNovel {
        ConnectedNovel(
            id: NovelID(3),
            title: "괴담에서 떨어져도 출근을 해야 하는구나",
            genre: .modernFantasy,
            rating: 1.2345)
    }

    private func makeMock(
        feedId: FeedID = FeedID(1),
        authorId: UserID = UserID(10),
        likeCount: Int = 0,
        isLiked: Bool = false,
        imageCount: Int = 0,
        thumbnail: URL? = nil
    ) -> TotalFeed {
        TotalFeed(
            feedId: feedId,
            createdDate: "2026-02-06",
            content: "테스트 내용",
            author: Author(userId: authorId,
                           nickname: "작성자",
                           profileImage: URL(string: "https://example.com/profile.jpg")),
            likeCount: likeCount,
            isLiked: isLiked,
            commentCount: 0,
            connectedNovel: makeMockConnectedNovel(),
            isSpoiler: false,
            isModified: false,
            isPublic: true,
            isMyFeed: false,
            thumbnailImageURL: thumbnail,
            imageCount: imageCount
        )
    }
}
