//
//  NovelNotificationSettingSheetViewModel.swift
//  NovelDetailFeature
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import NotificationDomain
import Logger
import Analytics

@MainActor
@Observable
final class NovelNotificationSettingSheetViewModel {

    // MARK: - State

    struct State {
        var isCompletionNotificationEnabled = false
        var isHiatusReturnNotificationEnabled = false
        /// 초기값 true — onAppear의 `.load`보다 첫 body 평가가 먼저라, false로 시작하면
        /// 로드 시작 전 한 프레임 동안 토글이 기본값(둘 다 off)으로 스친다(NovelDetailViewModel과 동일 이유).
        var isLoading = true
        /// 토글 서버 반영 중 — 두 토글이 항상 두 값을 함께 PUT하므로, 겹쳐 누르면 먼저 낸 요청의
        /// 응답으로 나중 요청이 덮이는 경합이 생긴다. 진행 중엔 새 토글을 막는다.
        var isSyncing = false
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호 — 로드/토글 어느 쪽에서
        /// 발생하든 여기로 모이며, View가 `onChange`로 소비한다(NovelDetailViewModel과 동일 패턴).
        var requiresAuthentication = false
        /// 로드 실패/토글 반영 실패(의미값) 공용. 토스트 표시용 — 시트가 작아 전체화면 에러 뷰를 둘 자리가
        /// 마땅치 않아 로드 실패도 토스트로만 알린다(닫고 다시 열면 재시도). 토글 실패는 값을 이전으로 되돌린다.
        var toastError: NovelNotificationSettingError?
    }

    /// 사용자에게 표시할 에러의 **의미값**. 카피·표현(토스트 타입)은 View가 결정한다.
    enum NovelNotificationSettingError: Equatable {
        case unknown
    }

    // MARK: - Action

    enum Action {
        case load
        case toggleCompletionNotification(Bool)
        case toggleHiatusReturnNotification(Bool)
        case dismissToast
        case disappear
        /// 시트가 아니라 이 VM을 들고 있는 화면(`NovelDetailView`) 자체가 닫힐 때 — `disappear()`와
        /// 달리 재진입을 가정하지 않으므로 로드까지 전부 취소한다(아래 `screenClosed()` 참고).
        case screenClosed
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    /// 시트가 스와이프 등으로 닫히는 중 — 명시적 닫기 버튼이 없어 View의 `.onDisappear`가 신호를 보낸다.
    @ObservationIgnored private var isClosing = false

    /// 낙관 반영 직전 스냅샷 — 실패 시 두 값을 통째로 이걸로 되돌린다(진행 중엔 `isSyncing`이
    /// 새 토글을 막아 스냅샷 하나로도 충분).
    private var currentSetting: NovelNotificationSetting {
        NovelNotificationSetting(
            isCompletionNotificationEnabled: state.isCompletionNotificationEnabled,
            isHiatusReturnNotificationEnabled: state.isHiatusReturnNotificationEnabled
        )
    }

    // MARK: - Dependency

    private let novelID: NovelID
    private let logger: Logger?
    private let analyticsTracker: AnalyticsTracker?

    // NotificationDomain
    private let loadNotificationSettingUseCase: LoadNovelNotificationSettingUseCase
    private let updateNotificationSettingUseCase: UpdateNovelNotificationSettingUseCase

    // MARK: - Init

    init(
        novelID: NovelID,
        loadNotificationSettingUseCase: LoadNovelNotificationSettingUseCase,
        updateNotificationSettingUseCase: UpdateNovelNotificationSettingUseCase,
        logger: Logger? = nil,
        analyticsTracker: AnalyticsTracker? = nil
    ) {
        self.novelID = novelID
        self.loadNotificationSettingUseCase = loadNotificationSettingUseCase
        self.updateNotificationSettingUseCase = updateNotificationSettingUseCase
        self.logger = logger
        self.analyticsTracker = analyticsTracker
    }

    // MARK: - Analytics

    func track(_ event: NovelDetailAnalyticsEvent, properties: [String: AnalyticsPropertyValue]? = nil) {
        analyticsTracker?.track(event, properties: properties)
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .toggleCompletionNotification(let isOn):
            toggleCompletionNotification(isOn)
        case .toggleHiatusReturnNotification(let isOn):
            toggleHiatusReturnNotification(isOn)
        case .dismissToast:
            state.toastError = nil
        case .disappear:
            disappear()
        case .screenClosed:
            screenClosed()
        }
    }
}

// MARK: - Action Handling

private extension NovelNotificationSettingSheetViewModel {
    func load() {
        // 이 VM은 이제 화면(NovelDetailView) 수명 내내 재사용된다 — 네비바 종 아이콘이 시트를 열지 않아도
        // 현재 알림 상태를 비춰야 해서, 시트가 열릴 때마다 새로 만들던 걸 화면 진입 시 한 번만 만들어
        // 들고 있는 방식으로 바꿨다. 그래서 시트를 닫을 때 세운 `isClosing`을 시트 재진입마다 반드시
        // 풀어야 한다 — 안 풀면 두 번째 여는 시트부터 토글이 전부 무시된다(아래 토글 가드가 영구 차단).
        isClosing = false
        // `isSyncing`도 같은 이유로 재진입마다 되돌려야 한다 — 토글 → PUT 진행 중에 시트를 닫으면
        // `disappear()`가 `syncTask`를 취소하지만, 그 시점 `isClosing`이 이미 true라 `sync()`의
        // defer가 `isSyncing`을 되돌리지 못하고 영구히 true로 남는다(리뷰에서 발견 — 이러면 그
        // 화면을 벗어났다 다시 들어오기 전까진 토글이 전부 무반응이 된다). `syncTask == nil`일
        // 때만 리셋해 혹시 남아있을 진행 중인 동기화는 건드리지 않는다.
        if syncTask == nil { state.isSyncing = false }
        guard !hasLoaded, loadTask == nil else { return }
        state.isLoading = true
        loadTask = Task { await loadSetting() }
    }

    func toggleCompletionNotification(_ isOn: Bool) {
        guard !state.isSyncing, !isClosing else { return }
        track(isOn ? .notificationCompletionOn : .notificationCompletionOff)
        let rollback = currentSetting
        state.isCompletionNotificationEnabled = isOn
        // Task 스케줄링 틈새에 두 토글이 동시에 들어와도 가드가 뚫리지 않도록, 스폰 전에 동기로 세운다.
        state.isSyncing = true
        syncTask = Task { await sync(rollbackTo: rollback) }
    }

    func toggleHiatusReturnNotification(_ isOn: Bool) {
        guard !state.isSyncing, !isClosing else { return }
        track(isOn ? .notificationHiatusOn : .notificationHiatusOff)
        let rollback = currentSetting
        state.isHiatusReturnNotificationEnabled = isOn
        state.isSyncing = true
        syncTask = Task { await sync(rollbackTo: rollback) }
    }

    /// 시트가 닫히는 중(스와이프 등) — 진행 중인 **토글 동기화만** 취소한다. 명시적 닫기 액션이 없는
    /// 시트라 이 신호를 `.onDisappear`가 대신 보낸다.
    /// ⚠️ `loadTask`는 여기서 취소하지 않는다 — 그 로드는 시트가 아니라 화면(`NovelDetailView`) 수명에
    /// 속한다(네비바 종 아이콘이 시트를 안 열어도 서버 상태를 비춰야 해서, `.onAppear`에서 시트와
    /// 무관하게 시작됨). 여기서 취소하면 시트를 열자마자 바로 닫는 것만으로 `hasLoaded`가 계속 false로
    /// 남아, 사용자가 시트를 다시 열기 전까지 아이콘이 부정확한 상태(빈 종)로 고착된다(리뷰에서 발견).
    /// ⚠️ 인스턴스 자체는 안 죽는다(화면 수명 내내 재사용, 위 `load()` 주석 참고) — "닫힘"은 일시
    /// 정지일 뿐이라 `isClosing`은 다음 `load()`(시트 재진입)에서 반드시 다시 풀린다.
    func disappear() {
        guard !isClosing else { return }
        isClosing = true
        syncTask?.cancel()
    }

    /// 시트가 아니라 이 VM을 들고 있는 화면(`NovelDetailView`) 자체가 닫히는 중 — `NovelDetailView`의
    /// `viewModel.state.shouldDismiss` onChange(뒤로가기 **버튼**, `NovelDetailViewModel.close()`와
    /// 같은 신호)에서만 부른다.
    /// ⚠️ **`.onDisappear`로 걸면 안 된다** — 이 화면은 `onRoute` 7종(작가 검색·평가·피드 등)으로 다른
    /// 화면을 자기 위에 push하는 "허브" 화면이라, `.onDisappear`는 진짜 종료가 아니라 **forward push
    /// 때도 SwiftUI 표준 동작으로 똑같이 발화한다**(`CollectionFeature/CLAUDE.md`에 이미 같은 함정이
    /// 실제 회귀로 기록돼 있다 — 그 문서가 "명시적 액션을 쓸 것"의 정본으로 바로 이 화면을 가리킨다).
    /// 그래서 명시적 신호로만 건다 — 대신 스와이프 뒤로가기는 이 경로를 안 타 정리가 안 되는데,
    /// `NovelDetailViewModel.close()` 자신도 스와이프에서 똑같이 안 불리는 이 화면의 기존 한계라
    /// 새로 생긴 갭은 아니다.
    /// `loadTask`까지 `disappear()`보다 더 넓게 정리한다는 점이 다르다. `isClosing` 값과 무관하게
    /// 항상 실행한다(시트가 이미 닫혀 `disappear()`로 `isClosing`이 true인 상태에서도, 그때 취소
    /// 안 하고 넘어간 `loadTask`가 여전히 돌고 있을 수 있어서 — `guard`로 걸러 스킵하면 그 잔여 로드를
    /// 놓친다). cancel은 nil/이미 완료된 Task에도 안전하다.
    func screenClosed() {
        isClosing = true
        loadTask?.cancel()
        syncTask?.cancel()
    }
}

// MARK: - UseCase Handling

private extension NovelNotificationSettingSheetViewModel {
    /// ⚠️ 이 로드는 `isClosing`(시트가 닫히는 중 신호)을 보지 않는다 — `disappear()`가 더 이상
    /// `loadTask`를 취소하지 않아서다(위 `disappear()` 주석 참고). 취소 여부는 오직 `Task.isCancelled`
    /// (`screenClosed()`가 진짜 취소할 때만 true)로만 판단한다.
    func loadSetting() async {
        defer {
            loadTask = nil
            state.isLoading = false
        }

        do {
            let setting = try await loadNotificationSettingUseCase.execute(novelID: novelID)
            guard !Task.isCancelled else { return }
            state.isCompletionNotificationEnabled = setting.isCompletionNotificationEnabled
            state.isHiatusReturnNotificationEnabled = setting.isHiatusReturnNotificationEnabled
            hasLoaded = true
        } catch {
            guard !Task.isCancelled else { return }
            presentError(error, log: "작품 알림 설정 로드 실패")
        }
    }

    /// PUT은 멱등이라 매번 두 값을 함께 보낸다(서버가 부분 갱신을 지원하지 않음).
    func sync(rollbackTo previous: NovelNotificationSetting) async {
        defer {
            syncTask = nil
            if !isClosing { state.isSyncing = false }
        }

        do {
            try await updateNotificationSettingUseCase.execute(novelID: novelID, setting: currentSetting)
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            state.isCompletionNotificationEnabled = previous.isCompletionNotificationEnabled
            state.isHiatusReturnNotificationEnabled = previous.isHiatusReturnNotificationEnabled
            presentError(error, log: "작품 알림 설정 변경 실패")
        }
    }
}

// MARK: - Error Mapping

private extension NovelNotificationSettingSheetViewModel {
    /// 인증 만료면 로그인 라우팅 신호로 일원화(개별 토스트 대신), 그 외엔 로그 남기고 토스트로 알린다.
    /// (`NovelDetailViewModel.presentError`/`routeToLoginIfAuthenticationRequired`와 동일 패턴.)
    func presentError(_ error: Error, log message: String) {
        guard (error as? RepositoryError) != .authenticationRequired else {
            state.requiresAuthentication = true
            return
        }
        logger?.error("\(message): \(String(describing: error))")
        state.toastError = .unknown
    }
}
