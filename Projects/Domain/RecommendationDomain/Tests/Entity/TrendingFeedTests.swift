//
//  TrendingFeedTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import RecommendationDomain
import RecommendationDomainTesting
import BaseDomain

@Suite
struct TrendingFeedTests {

    // MARK: - 생성

    @Test("지금 뜨는 글을 생성할 수 있다")
    func canCreateTrendingFeed() {
        let feed = makeTrendingFeed(feedID: FeedID(99), description: "인기 글 내용")

        #expect(feed.feedID == FeedID(99))
        #expect(feed.description == "인기 글 내용")
    }

    @Test("좋아요 수와 댓글 수를 포함한다")
    func includesLikeCountAndCommentCount() {
        let feed = makeTrendingFeed(likeCount: 150, commentCount: 30)

        #expect(feed.likeCount == 150)
        #expect(feed.commentCount == 30)
    }

    @Test("서로 다른 feedID로 구별할 수 있다")
    func canDistinguishByDifferentFeedIDs() {
        let feed1 = makeTrendingFeed(feedID: FeedID(1))
        let feed2 = makeTrendingFeed(feedID: FeedID(2))

        #expect(feed1.feedID != feed2.feedID)
    }

    // MARK: - 작품 정보

    @Test("글이 달린 작품의 제목·표지·장르를 함께 담는다")
    func carriesNovelInformation() {
        let thumbnail = URL(string: "https://image.example/cover.jpg")
        let feed = makeTrendingFeed(
            novelTitle: "우아한 오브리",
            novelThumbnailImage: thumbnail,
            novelGenre: .romanceFantasy
        )

        #expect(feed.novelTitle == "우아한 오브리")
        #expect(feed.novelThumbnailImage == thumbnail)
        #expect(feed.novelGenre == .romanceFantasy)
    }

    // MARK: - 스포일러

    @Test("스포일러 글도 원본 내용을 그대로 보관한다")
    func spoilerFeedKeepsOriginalDescription() {
        let feed = makeTrendingFeed(description: "원본 내용", isSpoiler: true)

        #expect(feed.isSpoiler)
        #expect(feed.description == "원본 내용")
    }

    @Test("스포일러가 아닌 글은 isSpoiler가 false다")
    func nonSpoilerFeedHasFalseFlag() {
        let feed = makeTrendingFeed(description: "원본 내용", isSpoiler: false)

        #expect(feed.isSpoiler == false)
    }
}

extension TrendingFeedTests {

    private func makeTrendingFeed(
        feedID: FeedID = FeedID(1),
        novelTitle: String = "테스트 작품",
        novelThumbnailImage: URL? = nil,
        novelGenre: NovelGenre = .romance,
        description: String = "지금 뜨는 글 내용",
        isSpoiler: Bool = false,
        likeCount: Int = 10,
        commentCount: Int = 5
    ) -> TrendingFeed {
        TrendingFeed(
            feedID: feedID,
            novelTitle: novelTitle,
            novelThumbnailImage: novelThumbnailImage,
            novelGenre: novelGenre,
            description: description,
            isSpoiler: isSpoiler,
            likeCount: likeCount,
            commentCount: commentCount
        )
    }
}
