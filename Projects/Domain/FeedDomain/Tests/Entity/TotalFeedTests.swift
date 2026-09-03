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

    @Test("상세로 갱신하면 본문·좋아요·댓글수·수정 여부·연결 작품·이미지가 상세 값으로 바뀐다")
    func updatedFromDetailTakesContentFieldsFromDetail() {
        let local = makeMock(likeCount: 1, isLiked: false)
        let firstImage = URL(string: "https://example.com/detail-1.jpg")
        let detail = makeMockDetail(
            content: "상세에서 수정된 본문",
            likeCount: 5,
            isLiked: true,
            commentCount: 3,
            isModified: true,
            imageURLs: [firstImage, URL(string: "https://example.com/detail-2.jpg")]
        )

        let updated = local.updated(from: detail)

        #expect(updated.content == "상세에서 수정된 본문")
        #expect(updated.likeCount == 5)
        #expect(updated.isLiked == true)
        #expect(updated.commentCount == 3)
        #expect(updated.isModified == true)
        #expect(updated.connectedNovel == detail.connectedNovel?.basicInfo)
        #expect(updated.thumbnailImageURL == firstImage)
        #expect(updated.imageCount == 2)
    }

    @Test("상세로 갱신해도 feedId·작성일·작성자·내 글 여부는 로컬 값을 유지한다")
    func updatedFromDetailKeepsLocalIdentityFields() {
        let local = makeMock(feedId: FeedID(7), authorId: UserID(10))
        // 상세의 author는 서버 원본(닉네임 다름) — 내 피드 목록이 프로필로 덧씌운 로컬 author가 이겨야 한다.
        let detail = makeMockDetail(authorNickname: "상세의 다른 닉네임")

        let updated = local.updated(from: detail)

        #expect(updated.feedId == FeedID(7))
        #expect(updated.createdDate == local.createdDate)
        #expect(updated.author.userId == UserID(10))
        #expect(updated.author.nickname == "작성자")
        #expect(updated.isMyFeed == local.isMyFeed)
    }

    @Test("이미지가 없는 상세로 갱신하면 썸네일이 비고 이미지 수는 0이다")
    func updatedFromDetailWithoutImagesClearsThumbnail() {
        let local = makeMock(imageCount: 2, thumbnail: URL(string: "https://example.com/old-thumb.jpg"))
        let detail = makeMockDetail(imageURLs: [])

        let updated = local.updated(from: detail)

        #expect(updated.thumbnailImageURL == nil)
        #expect(updated.imageCount == 0)
    }
}

extension TotalFeedTests {
    private func makeMockDetail(
        content: String = "상세 본문",
        authorNickname: String = "작성자",
        likeCount: Int = 0,
        isLiked: Bool = false,
        commentCount: Int = 0,
        isModified: Bool = false,
        imageURLs: [URL?] = []
    ) -> FeedDetail {
        FeedDetail(
            id: FeedID(1),
            author: Author(userId: UserID(10), nickname: authorNickname, profileImage: nil),
            createdDate: "2026-02-06",
            isModified: isModified,
            feedContent: content,
            feedImageURLs: imageURLs,
            connectedNovel: ConnectedNovelDetail(
                basicInfo: makeMockConnectedNovel(),
                thumbnailImageURL: nil,
                descirption: "소개"
            ),
            likeCount: likeCount,
            isLiked: isLiked,
            commentCount: commentCount,
            isSpoiler: false,
            isPublic: true
        )
    }

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
