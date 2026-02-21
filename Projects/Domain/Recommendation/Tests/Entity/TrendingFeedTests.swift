//
//  TrendingFeedTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import RecommendationDomain
@testable import BaseDomain

@Suite
struct TrendingFeedTests {

    // MARK: - Helpers

    private func makeTrendingFeed(
        feedID: FeedID = FeedID(1),
        description: String = "지금 뜨는 글 내용",
        likeCount: Int = 10,
        commentCount: Int = 5
    ) -> TrendingFeed {
        TrendingFeed(
            feedID: feedID,
            description: description,
            likeCount: likeCount,
            commentCount: commentCount
        )
    }

    // MARK: - Tests

    @Test func `지금 뜨는 글을 생성할 수 있다.`() {
        let feed = makeTrendingFeed(feedID: FeedID(99), description: "인기 글 내용")

        #expect(feed.feedID == FeedID(99))
        #expect(feed.description == "인기 글 내용")
    }

    @Test func `좋아요 수와 댓글 수를 포함한다.`() {
        let feed = makeTrendingFeed(likeCount: 150, commentCount: 30)

        #expect(feed.likeCount == 150)
        #expect(feed.commentCount == 30)
    }

    @Test func `서로 다른 feedID로 구별할 수 있다.`() {
        let feed1 = makeTrendingFeed(feedID: FeedID(1))
        let feed2 = makeTrendingFeed(feedID: FeedID(2))

        #expect(feed1.feedID != feed2.feedID)
    }
}
