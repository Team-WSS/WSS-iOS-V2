//
//  HomeViewModel.swift
//  HomeFeature
//
//  Created by YunhakLee on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import RecommendationDomain
import NotificationDomain
import Logger

@MainActor
@Observable
final class HomeViewModel {

    // MARK: - State

    struct State {
        /// 로컬 캐시 값이라 없을 수 있다. 추천글 섹션 제목의 주어가 된다.
        var nickname: String?
        var todayDiscoveries: [TodayDiscovery] = []
        var trendingFeeds: [TrendingFeed] = []
        /// nil = 아직 로드 전. `.noGenreSettings`(미설정)와 구분해야 로딩 중 설정 유도 CTA가 번쩍이지 않는다.
        var preferenceGenreNovelState: PreferenceGenreNovelState?
        var hasUnreadNotifications = false

        var isLoading = false
        var loadFailed = false
        var requiresAuthentication = false
    }

    // MARK: - Action

    enum Action {
        /// 진입·탭 복귀마다 발화한다(홈은 밖에서 바뀐 값을 다시 비춰야 해서 1회 가드를 두지 않는다).
        case load
        case consumeAuthenticationRequired
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    /// 진행 중인 로드. 탭을 빠르게 오가면 `.load`가 연달아 오므로 중복 요청을 막는다.
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    // MARK: - Dependency

    private let logger: Logger?

    // RecommendationDomain
    private let loadHomeDataUseCase: LoadHomeDataUseCase

    // NotificationDomain
    private let loadUnreadNotificationStatusUseCase: LoadUnreadNotificationStatusUseCase

    // MARK: - Init

    init(
        loadHomeDataUseCase: LoadHomeDataUseCase,
        loadUnreadNotificationStatusUseCase: LoadUnreadNotificationStatusUseCase,
        logger: Logger? = nil
    ) {
        self.loadHomeDataUseCase = loadHomeDataUseCase
        self.loadUnreadNotificationStatusUseCase = loadUnreadNotificationStatusUseCase
        self.logger = logger
        self.state = State()
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:                          load()
        case .consumeAuthenticationRequired: state.requiresAuthentication = false
        }
    }
}

// MARK: - Action Handling

private extension HomeViewModel {

    func load() {
        guard loadTask == nil else { return }

        loadTask = Task { [weak self] in
            await self?.loadHome()
            self?.loadTask = nil
        }
    }
}

// MARK: - UseCase Handling

private extension HomeViewModel {

    /// 추천 3종과 알림 배지를 한 흐름으로 본다 — 하나라도 실패하면 홈 전체가 실패다.
    func loadHome() async {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let homeData = try await loadHomeDataUseCase.execute()
            let notificationStatus = try await loadUnreadNotificationStatusUseCase.execute()

            state.nickname = homeData.nickname
            state.todayDiscoveries = homeData.todayDiscoveries
            state.trendingFeeds = homeData.trendingFeeds
            state.preferenceGenreNovelState = homeData.preferenceGenreNovelState
            state.hasUnreadNotifications = notificationStatus.hasUnreadNotifications
            state.loadFailed = false
        } catch {
            presentLoadFailure(error)
        }
    }
}

// MARK: - Error Mapping

private extension HomeViewModel {

    /// ⚠️ 인증 만료를 실패 플래그보다 **먼저** 걸러 return한다 — 순서를 뒤집으면 로그인 라우팅과
    /// 전면 실패 뷰가 동시에 걸린다(Feature 레이어의 인증 만료 처리 계약).
    func presentLoadFailure(_ error: RepositoryError) {
        guard !routeToLoginIfAuthenticationRequired(error) else { return }

        logger?.error("홈 데이터 로드 실패: \(error)")
        state.loadFailed = true
    }

    func routeToLoginIfAuthenticationRequired(_ error: RepositoryError) -> Bool {
        guard error == .authenticationRequired else { return false }

        state.requiresAuthentication = true
        return true
    }
}
