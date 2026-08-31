//
//  HomePrefetchStoreTests.swift
//  RecommendationDomainTests
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import RecommendationDomain
import BaseDomain

@Suite
struct HomePrefetchStoreTests {

    // MARK: - single-shot 소비

    @Test("채운 슬롯을 consume하면 그 값을 돌려주고 슬롯을 비운다")
    func consumeReturnsFilledValueAndEmptiesSlot() async {
        let store = HomePrefetchStore()
        let discoveries = [makeTodayDiscovery()]
        await store.fillTodayDiscoveries(discoveries)

        let first = await store.consumeTodayDiscoveries()
        let second = await store.consumeTodayDiscoveries()

        #expect(first?.map(\.novelID) == discoveries.map(\.novelID))
        #expect(second == nil)
    }

    @Test("채우지 않은 슬롯을 consume하면 nil을 돌려준다")
    func consumeEmptySlotReturnsNil() async {
        let store = HomePrefetchStore()

        let discoveries = await store.consumeTodayDiscoveries()
        let feeds = await store.consumeTrendingFeeds()

        #expect(discoveries == nil)
        #expect(feeds == nil)
    }

    @Test("소비한 뒤 다시 채우면 다시 한 번 소비할 수 있다")
    func refillAfterConsumeAllowsAnotherConsume() async {
        let store = HomePrefetchStore()
        let feeds = [makeTrendingFeed()]
        await store.fillTrendingFeeds(feeds)
        _ = await store.consumeTrendingFeeds()

        await store.fillTrendingFeeds(feeds)
        let second = await store.consumeTrendingFeeds()

        #expect(second?.map(\.feedID) == feeds.map(\.feedID))
    }

    // MARK: - 슬롯 독립성

    @Test("한 슬롯만 채우면 다른 슬롯은 여전히 nil이다")
    func slotsAreIndependent() async {
        let store = HomePrefetchStore()
        await store.fillTodayDiscoveries([makeTodayDiscovery()])

        let feeds = await store.consumeTrendingFeeds()

        #expect(feeds == nil)
    }

    @Test("한 슬롯의 소비가 다른 슬롯을 비우지 않는다")
    func consumingOneSlotKeepsTheOther() async {
        let store = HomePrefetchStore()
        let feeds = [makeTrendingFeed()]
        await store.fillTodayDiscoveries([makeTodayDiscovery()])
        await store.fillTrendingFeeds(feeds)

        _ = await store.consumeTodayDiscoveries()
        let remaining = await store.consumeTrendingFeeds()

        #expect(remaining?.map(\.feedID) == feeds.map(\.feedID))
    }
}

// MARK: - Helper

extension HomePrefetchStoreTests {

    private func makeTodayDiscovery() -> TodayDiscovery {
        TodayDiscovery(
            novelID: NovelID(1),
            novelTitle: "오늘의 발견",
            novelThumbnailImage: nil,
            novelAuthor: "테스트작가",
            novelGenre: .romance,
            publicationStatus: .onGoing,
            keywords: ["빙의"],
            content: .novel,
            contentDescription: "소설 설명"
        )
    }

    private func makeTrendingFeed() -> TrendingFeed {
        TrendingFeed(
            feedID: FeedID(1),
            novelTitle: "테스트 작품",
            novelThumbnailImage: nil,
            novelGenre: .romance,
            description: "뜨는 글 내용",
            isSpoiler: false,
            likeCount: 10,
            commentCount: 3
        )
    }
}
