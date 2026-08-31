//
//  DefaultLaunchTaskRepository.swift
//  SplashData
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import NotificationDomain
import ProfileDomain
import RecommendationDomain
import SplashDomain

/// `LaunchTaskRepository` 구현 — 로직 없이 기존 저장소들에 위임만 한다.
struct DefaultLaunchTaskRepository: LaunchTaskRepository {

    private let profileRepository: ProfileRepository
    private let pushSettingRepository: PushSettingRepository
    /// 현재 디바이스 푸시 토큰의 소스. 푸시 인프라(APNs/FCM)가 App에 배선되기 전까지는 nil을 돌려줘도 된다 —
    /// 그 경우 등록을 조용히 건너뛴다.
    private let deviceTokenProvider: @Sendable () async -> DevicePushToken?
    private let keywordRepository: KeywordRepository
    private let recommendationRepository: RecommendationRepository
    private let prefetchStore: HomePrefetchStore

    init(
        profileRepository: ProfileRepository,
        pushSettingRepository: PushSettingRepository,
        deviceTokenProvider: @escaping @Sendable () async -> DevicePushToken?,
        keywordRepository: KeywordRepository,
        recommendationRepository: RecommendationRepository,
        prefetchStore: HomePrefetchStore
    ) {
        self.profileRepository = profileRepository
        self.pushSettingRepository = pushSettingRepository
        self.deviceTokenProvider = deviceTokenProvider
        self.keywordRepository = keywordRepository
        self.recommendationRepository = recommendationRepository
        self.prefetchStore = prefetchStore
    }

    func syncUserBasicInfo() async throws(RepositoryError) {
        try await profileRepository.syncUserBasicInfo()
    }

    func registerDeviceTokenIfNeeded() async throws(RepositoryError) {
        guard let token = await deviceTokenProvider() else { return }
        try await pushSettingRepository.registerDeviceToken(token)
    }

    func syncKeywords() async {
        await keywordRepository.syncKeywords()
    }

    func prefetchHomeData() async {
        // 세 슬롯을 병렬로 채운다. 실패한 쪽은 비워둔다(홈이 네트워크로 폴백).
        // 홈 첫 페인트는 세 호출을 한꺼번에 기다리는 원자적 렌더라, 하나라도 안 데우면
        // 그 호출이 첫 페인트를 붙잡아 프리페치 이득이 사라진다 — 그래서 taste까지 셋 다 데운다.
        async let today: Void = prefetchTodayDiscoveries()
        async let trending: Void = prefetchTrendingFeeds()
        async let preference: Void = prefetchPreferenceGenreNovels()
        _ = await (today, trending, preference)
    }

    private func prefetchTodayDiscoveries() async {
        guard let discoveries = try? await recommendationRepository.fetchTodayDiscoveries() else { return }
        await prefetchStore.fillTodayDiscoveries(discoveries)
    }

    private func prefetchTrendingFeeds() async {
        guard let feeds = try? await recommendationRepository.fetchTrendingFeeds() else { return }
        await prefetchStore.fillTrendingFeeds(feeds)
    }

    /// taste는 개인화 응답이지만 `/novels/taste`가 `requireToken`이라 유효 토큰 없이는 실패해
    /// 슬롯이 안 채워진다(fail-closed) — 세션 전환 시 익명 데이터가 남는 today/trending의
    /// 함정(`docs/TODO.md` 11절)이 이 슬롯엔 없다.
    private func prefetchPreferenceGenreNovels() async {
        guard let state = try? await recommendationRepository.fetchPreferenceGenreNovels() else { return }
        await prefetchStore.fillPreferenceGenreNovels(state)
    }
}
