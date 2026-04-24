//
//  TrendingFeedTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import RecommendationDomain
import RecommendationDomainTesting
import BaseDomain

@Suite
struct TrendingFeedTests {

    // MARK: - Helpers

    private func makeTrendingFeed(
        feedID: FeedID = FeedID(1),
        description: String = "지금 뜨는 글 내용",
        isSpoiler: Bool = false,
        likeCount: Int = 10,
        commentCount: Int = 5
    ) -> TrendingFeed {
        TrendingFeed(
            feedID: feedID,
            description: description,
            isSpoiler: isSpoiler,
            likeCount: likeCount,
            commentCount: commentCount
        )
    }

    // MARK: - Tests

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

    @Test("스포일러가 포함된 글은 displayDescription이 스포일러 안내 문구로 대체된다")
    func spoilerFeedReplacesDisplayDescription() {
        let feed = makeTrendingFeed(description: "원본 내용", isSpoiler: true)

        #expect(feed.displayDescription == "스포일러가 포함된 글 보기")
        #expect(feed.description == "원본 내용")
    }

    @Test("스포일러가 아닌 글은 displayDescription이 원본 description과 동일하다")
    func nonSpoilerFeedKeepsOriginalDisplayDescription() {
        let feed = makeTrendingFeed(description: "원본 내용", isSpoiler: false)

        #expect(feed.displayDescription == "원본 내용")
        #expect(feed.description == "원본 내용")
    }
}
