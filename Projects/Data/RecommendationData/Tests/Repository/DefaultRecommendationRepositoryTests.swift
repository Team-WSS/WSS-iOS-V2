//
//  DefaultRecommendationRepositoryTests.swift
//  RecommendationDataTests
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import RecommendationData
import RecommendationDomain
import BaseDomain
import BaseData

/// 프리페치의 **소비하는 쪽** 배선 명세 — 홈 로드가 네트워크보다 먼저 `HomePrefetchStore`를 본다:
/// 슬롯에 값이 있으면 네트워크 없이 그 값을 쓰고(1회뿐), 없거나 store 미주입이면 평소처럼 네트워크로 간다.
/// 저장·소비 창 규칙 자체는 `HomePrefetchStoreTests`(RecommendationDomain)가,
/// 채우는 쪽은 `DefaultLaunchTaskRepositoryTests`(SplashData)가 명세한다.
@Suite
struct DefaultRecommendationRepositoryTests {

    // MARK: - 프리페치 소비 (single-shot)

    @Test("store에 프리페치된 오늘의 발견이 있으면 네트워크를 부르지 않고 그 값을 반환한다")
    func todayDiscoveriesConsumesPrefetchWithoutNetwork() async throws {
        let service = MockRecommendationService()
        let store = HomePrefetchStore()
        await store.fillTodayDiscoveries([makeTodayDiscovery()])
        let sut = makeSUT(service: service, prefetchStore: store)

        let result = try await sut.fetchTodayDiscoveries()

        #expect(result.map(\.novelID) == [NovelID(99)])
        #expect(service.getTodayDiscoveryCallCount == 0)
    }

    @Test("프리페치 소비는 1회뿐 — 같은 호출을 반복하면 네트워크로 간다")
    func secondFetchGoesToNetworkAfterConsume() async throws {
        let service = MockRecommendationService()
        let store = HomePrefetchStore()
        await store.fillTodayDiscoveries([makeTodayDiscovery()])
        let sut = makeSUT(service: service, prefetchStore: store)

        _ = try await sut.fetchTodayDiscoveries()
        _ = try await sut.fetchTodayDiscoveries()

        #expect(service.getTodayDiscoveryCallCount == 1)
    }

    @Test("store에 프리페치된 지금 뜨는 글이 있으면 네트워크를 부르지 않고 그 값을 반환한다")
    func trendingFeedsConsumesPrefetchWithoutNetwork() async throws {
        let service = MockRecommendationService()
        let store = HomePrefetchStore()
        await store.fillTrendingFeeds([makeTrendingFeed()])
        let sut = makeSUT(service: service, prefetchStore: store)

        let result = try await sut.fetchTrendingFeeds()

        #expect(result.map(\.feedID) == [FeedID(77)])
        #expect(service.getTrendingFeedsCallCount == 0)
    }

    @Test("store에 프리페치된 선호장르가 있으면 네트워크를 부르지 않고 그 값을 반환한다")
    func preferenceGenreNovelsConsumesPrefetchWithoutNetwork() async throws {
        let service = MockRecommendationService()
        let store = HomePrefetchStore()
        await store.fillPreferenceGenreNovels(.noGenreSettings)
        let sut = makeSUT(service: service, prefetchStore: store)

        let result = try await sut.fetchPreferenceGenreNovels()

        if case .noGenreSettings = result {} else { Issue.record("프리페치된 상태 그대로 돌아와야 한다") }
        #expect(service.getPreferenceGenreNovelsCallCount == 0)
    }

    @Test("store가 주입되지 않으면 항상 네트워크로 간다")
    func withoutStoreAlwaysGoesToNetwork() async throws {
        let service = MockRecommendationService()
        let sut = makeSUT(service: service, prefetchStore: nil)

        _ = try await sut.fetchTodayDiscoveries()

        #expect(service.getTodayDiscoveryCallCount == 1)
    }

    @Test("store가 비어 있으면 네트워크로 간다")
    func emptyStoreGoesToNetwork() async throws {
        let service = MockRecommendationService()
        let sut = makeSUT(service: service, prefetchStore: HomePrefetchStore())

        _ = try await sut.fetchTrendingFeeds()

        #expect(service.getTrendingFeedsCallCount == 1)
    }
}

// MARK: - Helper

extension DefaultRecommendationRepositoryTests {

    private func makeSUT(
        service: MockRecommendationService,
        prefetchStore: HomePrefetchStore?
    ) -> DefaultRecommendationRepository {
        DefaultRecommendationRepository(
            service: service,
            appStorage: EmptyAppStorage(),
            logger: nil,
            prefetchStore: prefetchStore
        )
    }

    private func makeTodayDiscovery() -> TodayDiscovery {
        TodayDiscovery(
            novelID: NovelID(99),
            novelTitle: "프리페치된 소설",
            novelThumbnailImage: nil,
            novelAuthor: "작가",
            novelGenre: .romance,
            publicationStatus: .onGoing,
            keywords: [],
            content: .novel,
            contentDescription: "소개"
        )
    }

    private func makeTrendingFeed() -> TrendingFeed {
        TrendingFeed(
            feedID: FeedID(77),
            novelTitle: "프리페치된 작품",
            novelThumbnailImage: nil,
            novelGenre: .romance,
            description: "내용",
            isSpoiler: false,
            likeCount: 1,
            commentCount: 0
        )
    }
}

// MARK: - Test Doubles

/// 이 테스트에서 로컬 스토리지는 관심 밖 — 항상 빈 값을 돌려준다.
private struct EmptyAppStorage: AppStorage {
    func get<V>(_ key: StorageKey<V>) -> V? { nil }
    func set<V>(_ key: StorageKey<V>, _ value: V?) {}
}

// MARK: - Mock Service

private final class MockRecommendationService: RecommendationService, @unchecked Sendable {

    private(set) var getTodayDiscoveryCallCount = 0
    private(set) var getTrendingFeedsCallCount = 0
    private(set) var getPreferenceGenreNovelsCallCount = 0

    func getTodayDiscovery() async throws -> TodayDiscoveryNovelsResponse {
        getTodayDiscoveryCallCount += 1
        return TodayDiscoveryNovelsResponse(popularNovels: [
            TodayDiscoveryNovelResponse(
                novelId: 1,
                title: "네트워크 소설",
                novelImage: "https://example.com/novel.jpg",
                author: "작가A",
                genreName: "romance",
                isNovelCompleted: false,
                keywords: ["빙의"],
                novelDescription: "작품 소개글",
                avatarImage: nil,
                nickname: nil,
                feedContent: nil
            )
        ])
    }

    func getTrendingFeeds() async throws -> TrendingFeedsResponse {
        getTrendingFeedsCallCount += 1
        return TrendingFeedsResponse(popularFeeds: [
            TrendingFeedResponse(
                feedId: 1,
                feedContent: "네트워크 글",
                likeCount: 5,
                commentCount: 1,
                isSpoiler: false,
                isPublic: true,
                novelTitle: "작품",
                novelImage: "https://example.com/novel.jpg",
                novelGenre: "romance"
            )
        ])
    }

    func getInterestFeeds() async throws -> InterestFeedsResponse {
        fatalError("이 테스트에서 호출되면 안 된다")
    }

    func getPreferenceGenreNovels() async throws -> PreferenceGenreNovelsResponse {
        getPreferenceGenreNovelsCallCount += 1
        return PreferenceGenreNovelsResponse(tasteNovels: [])
    }

    func getSosopickNovels() async throws -> SosopickNovelsResponse {
        fatalError("이 테스트에서 호출되면 안 된다")
    }
}
