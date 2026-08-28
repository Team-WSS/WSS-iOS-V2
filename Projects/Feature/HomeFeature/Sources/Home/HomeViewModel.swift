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
import PushAuthorization

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

        /// ⚠️ 초깃값 `true` — `onAppear`의 `.load`보다 첫 body 평가가 먼저라, false면 한 프레임 동안
        /// "검색바·배너만 있는 빈 홈"이 스친다(Library·NovelDetail과 같은 이유).
        var isLoading = true
        var loadFailed = false
        var requiresAuthentication = false
        /// 알림 목록 화면으로 이동해도 되는 신호 — **벨 탭 즉시** 오른다. View가 `onChange`로 소비하고
        /// 곧바로 `.consumeNotificationNavigation`으로 되돌린다(`requiresAuthentication`과 같은 1회성
        /// 신호 패턴 — 이 VM은 탭 세션 내내 살아서 소진해야 두 번째 벨 탭도 신호가 삼켜지지 않는다).
        /// 푸시 권한이 denied라 기기 설정 유도 알럿을 띄워야 하는지는 이 화면이 아니라 **이동한 뒤의
        /// 알림 목록 화면(App이 push)이 판단한다** — `showWSSAlert`가 `.overlay` 기반이라 push 전환과
        /// 동시에 띄우면 그 전환에 밀려 사라지기 때문(`SettingFeature`의 알림 설정 메뉴와 같은 함정).
        var shouldNavigateToNotifications = false
    }

    // MARK: - Derived

    /// 로딩 뷰로 화면을 덮어도 되는 순간 — **아직 보여줄 게 없을 때뿐**이다.
    /// 홈은 탭 복귀마다 다시 로드하므로, 이미 그린 콘텐츠까지 매번 걷어내면 스크롤 위치와
    /// 추천글 페이지가 초기화되고 갱신할 때마다 화면이 통째로 깜빡인다.
    var isInitialLoading: Bool {
        state.isLoading && !hasLoadedContent
    }

    // MARK: - Action

    enum Action {
        /// 진입·탭 복귀마다 발화한다(홈은 밖에서 바뀐 값을 다시 비춰야 해서 1회 가드를 두지 않는다).
        case load
        case consumeAuthenticationRequired
        case notificationBellTapped
        case consumeNotificationNavigation
        /// 홈 진입마다 발화 — 첫 회원가입 직후 첫 홈 진입이 이 앱에서 유저가 처음 겪는 알림 권한
        /// 결정 시점이 되도록 한다(#193). `.load`와 짝을 이루지만 홈 데이터 로드와는 무관한 별도 흐름.
        case checkPushAuthorizationOnEntry
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    /// 진행 중인 로드. 탭을 빠르게 오가면 `.load`가 연달아 오므로 중복 요청을 막는다.
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    /// 지금 화면에 그릴 콘텐츠가 서 있는지.
    /// ⚠️ **`state`의 배열로 판단하지 말 것** — 갱신이 실패해도 배열엔 직전 성공 데이터가 그대로 남아
    /// 있어서, 배열로 보면 실패 뷰에서 재시도할 때 로딩 대신 **옛 홈이 잠깐 되살아났다가 다시 실패 뷰로
    /// 튄다**(성공한 것처럼 보였다가 슬램). 그래서 로드 결과로만 오르내리는 플래그를 따로 둔다.
    @ObservationIgnored private var hasLoadedContent = false

    // MARK: - Dependency

    private let logger: Logger?

    // RecommendationDomain
    private let loadHomeDataUseCase: LoadHomeDataUseCase

    // NotificationDomain
    private let loadUnreadNotificationStatusUseCase: LoadUnreadNotificationStatusUseCase

    // PushAuthorization
    private let pushAuthorizationChecker: PushAuthorizationChecker

    // MARK: - Init

    init(
        loadHomeDataUseCase: LoadHomeDataUseCase,
        loadUnreadNotificationStatusUseCase: LoadUnreadNotificationStatusUseCase,
        pushAuthorizationChecker: PushAuthorizationChecker,
        logger: Logger? = nil
    ) {
        self.loadHomeDataUseCase = loadHomeDataUseCase
        self.loadUnreadNotificationStatusUseCase = loadUnreadNotificationStatusUseCase
        self.pushAuthorizationChecker = pushAuthorizationChecker
        self.logger = logger
        self.state = State()
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:                          load()
        case .consumeAuthenticationRequired: state.requiresAuthentication = false
        case .notificationBellTapped:        state.shouldNavigateToNotifications = true
        case .consumeNotificationNavigation: state.shouldNavigateToNotifications = false
        case .checkPushAuthorizationOnEntry: checkPushAuthorizationOnEntry()
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

    /// notDetermined면 그 자리에서 시스템 프롬프트를 띄운다 — 온보딩 완료 후 첫 홈 진입이 유저가
    /// 이 앱에서 처음 만나는 알림 권한 결정 시점이 되도록 하기 위함(#193). authorized/denied는
    /// 여기서 아무것도 하지 않는다(denied 유도 알럿은 벨 탭 때만 뜬다 — 진입만으로 알럿을 띄우면
    /// 매번 홈에 올 때마다 거슬린다). 이 진입점이 있으면 이후 벨 탭·알림 설정 화면에서
    /// notDetermined를 만날 일이 사실상 없다(이미 authorized/denied로 확정된 뒤라서) — 그 두 곳의
    /// notDetermined 분기는 방어적으로만 남아 있다(예: 진입 체크가 아직 안 끝난 채 빠르게 벨을 누른 경우).
    func checkPushAuthorizationOnEntry() {
        Task { [weak self] in
            guard let self else { return }
            guard await pushAuthorizationChecker.authorizationStatus() == .notDetermined else { return }
            _ = await pushAuthorizationChecker.requestAuthorization()
        }
    }
}

// MARK: - UseCase Handling

private extension HomeViewModel {

    /// 추천 3종과 알림 배지를 한 흐름으로 본다 — 하나라도 실패하면 홈 전체가 실패다.
    func loadHome() async {
        state.isLoading = true
        // 재시도·재진입 시작 시점에 함께 내린다 — 성공할 때만 내리면 "페이지 다시 불러오기"를 눌러도
        // 로드가 끝날 때까지 실패 뷰가 그대로라 아무 반응이 없어 보인다.
        state.loadFailed = false
        defer { state.isLoading = false }

        do {
            // 둘은 서로 독립이라 동시에 부른다 — 순차로 펴면 왕복 지연이 그대로 더해지는데,
            // 홈은 탭 복귀마다 갱신하는 화면이라 그 비용을 매번 낸다.
            async let homeData = loadHomeDataUseCase.execute()
            async let notificationStatus = loadUnreadNotificationStatusUseCase.execute()

            let loadedHomeData = try await homeData
            let loadedNotificationStatus = try await notificationStatus

            // 플래그를 state보다 **먼저** 올린다 — 관찰 대상이 아니라 갱신을 스스로 트리거하지 않으므로,
            // 뷰를 깨우는 state 대입 시점에 이미 최신값이어야 한다(아래 실패 경로도 같은 이유로 먼저 내린다).
            hasLoadedContent = true

            state.nickname = loadedHomeData.nickname
            state.todayDiscoveries = loadedHomeData.todayDiscoveries
            state.trendingFeeds = loadedHomeData.trendingFeeds
            state.preferenceGenreNovelState = loadedHomeData.preferenceGenreNovelState
            state.hasUnreadNotifications = loadedNotificationStatus.hasUnreadNotifications
        } catch let error as RepositoryError {
            presentLoadFailure(error)
        } catch {
            // ⚠️ `async let`이 UseCase의 타입 지정 throw를 `any Error`로 지워서 분기가 필요하다.
            // 두 UseCase 모두 RepositoryError만 던지므로 여기는 실제로는 도달하지 않는다.
            presentLoadFailure(.unknown)
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
        // 실패 뷰가 화면을 덮으므로 "보이는 콘텐츠"는 없어진다 — 이걸 내려야 재시도 때 옛 홈이
        // 되살아나지 않고 로딩부터 다시 시작한다. (인증 만료는 위에서 return되어 여기 오지 않는다 —
        // 그쪽은 실패 뷰를 세우지 않으니 콘텐츠가 남아도 맞다.)
        hasLoadedContent = false
        state.loadFailed = true
    }

    func routeToLoginIfAuthenticationRequired(_ error: RepositoryError) -> Bool {
        guard error == .authenticationRequired else { return false }

        state.requiresAuthentication = true
        return true
    }
}
