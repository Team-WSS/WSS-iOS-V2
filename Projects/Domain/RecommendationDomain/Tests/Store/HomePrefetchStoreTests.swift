//
//  HomePrefetchStoreTests.swift
//  RecommendationDomainTests
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain
import RecommendationDomain

/// 런치스크린에서 미리 받아 둔 홈 데이터를 홈 첫 로드가 한 번 꺼내 쓰는 저장고(#225).
/// 채우는 쪽은 SplashData, 꺼내는 쪽은 RecommendationData다.
@Suite("런치스크린에서 미리 받아 둔 홈 데이터")
struct HomePrefetchStoreTests {

    /// 홈은 탭 복귀마다 새로 불러온다 — 한 번 꺼낸 값이 남아 있으면 복귀 때 런치 시점 데이터가 다시 뜬다.
    @Suite("홈 첫 로드에서 한 번만 쓴다")
    struct ConsumeOnce {

        @Test("홈 첫 로드는 미리 받아 둔 세 가지를 그대로 받는다")
        func consumesFilledValueFromEachSlot() async {
            let store = HomePrefetchStore()
            // 슬롯마다 id를 다르게 둬서, 값이 다른 슬롯으로 새지 않았는지 보이게 한다.
            await store.fillTodayDiscoveries([makeTodayDiscovery(id: 1)])
            await store.fillTrendingFeeds([makeTrendingFeed(id: 2)])
            await store.fillPreferenceGenreNovels(.novels([makePreferenceGenreNovel(id: 3)]))

            let consumed = (
                await store.consumeTodayDiscoveries(),
                await store.consumeTrendingFeeds(),
                await store.consumePreferenceGenreNovels()
            )

            #expect(consumed.0?.map(\.novelID) == [NovelID(1)])
            #expect(consumed.1?.map(\.feedID) == [FeedID(2)])
            #expect(consumed.2.flatMap(novelIDs(in:)) == [NovelID(3)])
        }

        @Test("홈 첫 로드가 쓰고 나면 탭 복귀 때는 미리 받아 둔 값이 없다")
        func consumedSlotIsEmpty() async {
            let store = HomePrefetchStore()
            await store.fillTodayDiscoveries([makeTodayDiscovery(id: 1)])
            _ = await store.consumeTodayDiscoveries()

            let second = await store.consumeTodayDiscoveries()

            #expect(second == nil)
        }

        @Test("미리 받아 둔 게 없으면 홈 첫 로드도 받을 값이 없다")
        func unfilledSlotIsEmpty() async {
            let store = HomePrefetchStore()

            let consumed = (
                await store.consumeTodayDiscoveries(),
                await store.consumeTrendingFeeds(),
                await store.consumePreferenceGenreNovels()
            )

            #expect(consumed.0 == nil)
            #expect(consumed.1 == nil)
            #expect(consumed.2 == nil)
        }
    }

    /// 프리페치는 기다리지 않고 던져 두는 요청이라 홈 첫 로드보다 늦게 도착할 수 있다.
    /// 그 값을 받아 두면 다음 탭 복귀 갱신에서 꺼내져 런치 시점 데이터가 뒤늦게 뜬다(#225 리뷰).
    @Suite("홈 첫 로드가 지난 뒤 도착한 값은 쓰지 않는다")
    struct DiscardLateFill {

        @Test("홈 첫 로드가 쓴 뒤 다시 받아 온 값은 탭 복귀 때 쓰지 않는다")
        func fillAfterConsumeIsDiscarded() async {
            let store = HomePrefetchStore()
            await store.fillTrendingFeeds([makeTrendingFeed(id: 1)])
            _ = await store.consumeTrendingFeeds()
            await store.fillTrendingFeeds([makeTrendingFeed(id: 2)])

            let second = await store.consumeTrendingFeeds()

            #expect(second == nil)
        }

        @Test("홈 첫 로드보다 늦게 도착한 값은 탭 복귀 때 쓰지 않는다")
        func lateFillAfterEmptyConsumeIsDiscarded() async {
            let store = HomePrefetchStore()
            _ = await store.consumeTodayDiscoveries()   // 홈 첫 로드 — 아직 비어 있어 서버로 간다
            await store.fillTodayDiscoveries([makeTodayDiscovery(id: 1)])   // 늦게 도착한 프리페치

            let second = await store.consumeTodayDiscoveries()   // 탭 복귀 갱신

            #expect(second == nil)
        }
    }
}

// MARK: - Helper

private func novelIDs(in state: PreferenceGenreNovelState) -> [NovelID]? {
    guard case .novels(let novels) = state else { return nil }
    return novels.map(\.novelID)
}

private func makeTodayDiscovery(id: Int) -> TodayDiscovery {
    TodayDiscovery(
        novelID: NovelID(id),
        novelTitle: "오늘의 발견",
        novelThumbnailImage: nil,
        novelAuthor: "작가",
        novelGenre: .romance,
        publicationStatus: .onGoing,
        keywords: [],
        content: .novel,
        contentDescription: "작품 소개"
    )
}

private func makeTrendingFeed(id: Int) -> TrendingFeed {
    TrendingFeed(
        feedID: FeedID(id),
        novelTitle: "작품",
        novelThumbnailImage: nil,
        novelGenre: .romance,
        description: "지금 뜨는 글",
        isSpoiler: false,
        likeCount: 0,
        commentCount: 0
    )
}

private func makePreferenceGenreNovel(id: Int) -> PreferenceGenreNovel {
    PreferenceGenreNovel(
        novelID: NovelID(id),
        novelTitle: "선호 장르 작품",
        novelThumbnailImage: nil,
        novelAuthors: [],
        interestCount: 0,
        ratingCount: 0,
        rating: 0
    )
}
