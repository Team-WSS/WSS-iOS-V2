//
//  InterestFeedTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import RecommendationDomain
@testable import BaseDomain

@Suite
struct InterestFeedTests {

    // MARK: - Helpers

    private func makeInterestFeed(
        novelID: NovelID = NovelID(1),
        novelTitle: String = "테스트 소설",
        novelRating: Float = 4.5,
        novelRatingCount: Int = 100,
        userComment: String = "재미있는 소설입니다"
    ) -> InterestFeed {
        InterestFeed(
            novelID: novelID,
            novelTitle: novelTitle,
            novelThumbnailImage: nil,
            novelRating: novelRating,
            novelRatingCount: novelRatingCount,
            user: Author(
                userId: UserID(1),
                nickname: "테스트유저",
                profileImage: ImageWrapper(identifier: "profile")
            ),
            userComment: userComment
        )
    }

    // MARK: - feeds 상태

    @Test func `feeds 상태에서 피드 목록을 확인할 수 있다.`() {
        let feed = makeInterestFeed(novelTitle: "소설 제목")
        let state = InterestFeedState.feeds([feed])

        guard case .feeds(let feeds) = state else {
            Issue.record("feeds 상태여야 합니다")
            return
        }

        #expect(feeds.count == 1)
        #expect(feeds.first?.novelTitle == "소설 제목")
    }

    @Test func `feeds 상태에서 여러 피드를 포함할 수 있다.`() {
        let feeds = [makeInterestFeed(), makeInterestFeed(), makeInterestFeed()]
        let state = InterestFeedState.feeds(feeds)

        guard case .feeds(let result) = state else {
            Issue.record("feeds 상태여야 합니다")
            return
        }

        #expect(result.count == 3)
    }

    @Test func `feeds 상태에서 피드 목록이 비어있을 수 있다.`() {
        let state = InterestFeedState.feeds([])

        guard case .feeds(let feeds) = state else {
            Issue.record("feeds 상태여야 합니다")
            return
        }

        #expect(feeds.isEmpty)
    }

    // MARK: - 비활성 상태

    @Test func `관심 설정을 하지 않은 상태를 표현할 수 있다.`() {
        let state = InterestFeedState.noInterestSettings

        var isMatch = false
        if case .noInterestSettings = state { isMatch = true }

        #expect(isMatch)
    }

    @Test func `관련 피드가 없는 상태를 표현할 수 있다.`() {
        let state = InterestFeedState.noAssociatedFeeds

        var isMatch = false
        if case .noAssociatedFeeds = state { isMatch = true }

        #expect(isMatch)
    }
}
