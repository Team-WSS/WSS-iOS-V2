//
//  DefaultLaunchTaskRepositoryTests.swift
//  SplashDataTests
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import SplashData
import BaseDomain
import BaseDomainTesting
import NotificationDomain
import NotificationDomainTesting
import ProfileDomain
import ProfileDomainTesting
import RecommendationDomain
import RecommendationDomainTesting

/// 부수 태스크 4종(users/me 동기화·FCM 토큰 등록·키워드 동기화·홈 프리페치)을
/// **각 도메인 Repository에 어떻게 위임하는지** 명세. 여기 있는 분기는 둘뿐이다 —
/// 토큰 소스가 없으면 FCM 등록을 조용히 건너뛰는 것, 프리페치 두 슬롯을 병렬로 채우되
/// 실패한 쪽만 비워 두는 것. "언제 던지고 언제 기다리는지"는 `BootstrapAppUseCaseTests`가 명세한다.
@Suite
struct DefaultLaunchTaskRepositoryTests {

    // MARK: - 위임

    @Test("users me 동기화를 ProfileRepository에 위임한다")
    func delegatesUserSyncToProfileRepository() async throws {
        let profile = MockProfileRepository()
        let sut = makeSUT(profileRepository: profile)

        try await sut.syncUserBasicInfo()

        #expect(profile.syncUserBasicInfoCallCount == 1)
    }

    @Test("키워드 동기화를 KeywordRepository에 위임한다")
    func delegatesKeywordSyncToKeywordRepository() async {
        let keyword = MockKeywordRepository()
        let sut = makeSUT(keywordRepository: keyword)

        await sut.syncKeywords()

        #expect(keyword.syncKeywordsCallCount == 1)
    }

    // MARK: - 디바이스 토큰

    @Test("디바이스 토큰이 있으면 그 토큰을 서버에 등록한다")
    func registersDeviceTokenWhenAvailable() async throws {
        let push = MockPushSettingRepository()
        let token = DevicePushToken(token: "fcm-token", deviceID: "device-1")
        let sut = makeSUT(pushSettingRepository: push, deviceToken: token)

        try await sut.registerDeviceTokenIfNeeded()

        #expect(push.registerCallCount == 1)
        #expect(push.lastRegisteredToken == token)
    }

    @Test("디바이스 토큰 소스가 없으면 등록을 조용히 건너뛴다")
    func skipsRegistrationWhenTokenUnavailable() async throws {
        let push = MockPushSettingRepository()
        let sut = makeSUT(pushSettingRepository: push, deviceToken: nil)

        try await sut.registerDeviceTokenIfNeeded()

        #expect(push.registerCallCount == 0)
    }

    // MARK: - 홈 프리페치

    @Test("프리페치가 성공하면 두 슬롯을 모두 채운다")
    func prefetchFillsBothSlots() async {
        let recommendation = MockRecommendationRepository()
        recommendation.fetchTodayDiscoveriesResult = .success([makeTodayDiscovery()])
        recommendation.fetchTrendingFeedsResult = .success([makeTrendingFeed()])
        let store = HomePrefetchStore()
        let sut = makeSUT(recommendationRepository: recommendation, prefetchStore: store)

        await sut.prefetchHomeData()

        #expect(await store.consumeTodayDiscoveries() != nil)
        #expect(await store.consumeTrendingFeeds() != nil)
    }

    @Test("프리페치가 실패한 슬롯은 비워두고 성공한 슬롯만 채운다")
    func prefetchFailureLeavesSlotEmpty() async {
        let recommendation = MockRecommendationRepository()
        recommendation.fetchTodayDiscoveriesResult = .failure(.serverUnavailable)
        recommendation.fetchTrendingFeedsResult = .success([makeTrendingFeed()])
        let store = HomePrefetchStore()
        let sut = makeSUT(recommendationRepository: recommendation, prefetchStore: store)

        await sut.prefetchHomeData()

        #expect(await store.consumeTodayDiscoveries() == nil)
        #expect(await store.consumeTrendingFeeds() != nil)
    }
}

// MARK: - Helper

extension DefaultLaunchTaskRepositoryTests {

    private func makeSUT(
        profileRepository: MockProfileRepository = MockProfileRepository(),
        pushSettingRepository: MockPushSettingRepository = MockPushSettingRepository(),
        deviceToken: DevicePushToken? = nil,
        keywordRepository: MockKeywordRepository = MockKeywordRepository(),
        recommendationRepository: MockRecommendationRepository = MockRecommendationRepository(),
        prefetchStore: HomePrefetchStore = HomePrefetchStore()
    ) -> DefaultLaunchTaskRepository {
        DefaultLaunchTaskRepository(
            profileRepository: profileRepository,
            pushSettingRepository: pushSettingRepository,
            deviceTokenProvider: { deviceToken },
            keywordRepository: keywordRepository,
            recommendationRepository: recommendationRepository,
            prefetchStore: prefetchStore
        )
    }

    private func makeTodayDiscovery() -> TodayDiscovery {
        TodayDiscovery(
            novelID: NovelID(1),
            novelTitle: "오늘의 발견",
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
            feedID: FeedID(1),
            novelTitle: "작품",
            novelThumbnailImage: nil,
            novelGenre: .romance,
            description: "내용",
            isSpoiler: false,
            likeCount: 0,
            commentCount: 0
        )
    }
}
