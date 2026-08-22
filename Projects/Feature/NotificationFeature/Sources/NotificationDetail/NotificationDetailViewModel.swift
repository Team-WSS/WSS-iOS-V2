//
//  NotificationDetailViewModel.swift
//  NotificationFeature
//
//  Created by YunhakLee on 8/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import NotificationDomain
import Logger

@MainActor
@Observable
final class NotificationDetailViewModel {

    // MARK: - State

    struct State {
        /// nil이면 아직 로드 전 — 로딩·실패 분기가 끝난 뒤에만 채워진다.
        var detail: NotificationDetail?
        /// 초기값 true — onAppear의 `.load`보다 첫 body 평가가 먼저라, false로 시작하면
        /// 로드 시작 전 한 프레임 동안 빈 화면이 스친다.
        var isLoading = true
        /// 로드 실패 여부 — View가 전면 실패 뷰(재시도)를 그리는 기준.
        var loadFailed = false
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호.
        var requiresAuthentication = false
    }

    // MARK: - Action

    enum Action {
        case load
        case retry
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    /// 1회 가드 플래그는 실패 고착을 막기 위해 **성공 시에만** 소진한다.
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    // MARK: - Dependency

    /// 조회 대상 알림. 진입 이전 화면(알림 목록)이 주입한다.
    private let notificationID: NotificationID
    private let logger: Logger?

    // NotificationDomain
    private let loadNotificationDetailUseCase: LoadNotificationDetailUseCase

    // MARK: - Init

    init(
        notificationID: NotificationID,
        loadNotificationDetailUseCase: LoadNotificationDetailUseCase,
        logger: Logger? = nil
    ) {
        self.notificationID = notificationID
        self.loadNotificationDetailUseCase = loadNotificationDetailUseCase
        self.logger = logger
        self.state = State()
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .retry:
            retry()
        }
    }
}

// MARK: - Action Handling

private extension NotificationDetailViewModel {

    /// 진입 시 로드. onAppear는 재진입마다 불리므로 성공 후에는 다시 로드하지 않되,
    /// 실패는 가드를 소진하지 않아 재진입 시 재시도가 열려 있다.
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        startLoad()
    }

    /// 전면 실패 뷰의 재시도.
    func retry() {
        guard loadTask == nil else { return }
        startLoad()
    }

    func startLoad() {
        state.isLoading = true
        state.loadFailed = false
        loadTask = Task { await loadDetail() }
    }
}

// MARK: - UseCase Handling

private extension NotificationDetailViewModel {

    func loadDetail() async {
        defer {
            loadTask = nil
            state.isLoading = false
        }
        do {
            let detail = try await loadNotificationDetailUseCase.execute(id: notificationID)
            guard !Task.isCancelled else { return }
            state.detail = detail
            state.loadFailed = false
            hasLoaded = true
        } catch {
            guard !Task.isCancelled else { return }
            // 인증 만료는 실패 뷰 대신 로그인 유도로 일원화 — 실패 플래그보다 먼저 거른다.
            if routeToLoginIfAuthenticationRequired(error) { return }
            state.loadFailed = true
            logger?.error("NotificationDetail 실패(load): \(String(describing: error))")
        }
    }
}

// MARK: - Error Mapping

private extension NotificationDetailViewModel {

    /// 인증 만료(`authenticationRequired`)면 로그인 라우팅 신호를 세우고 true 반환.
    /// 세션이 죽은 상황이라 실패 뷰 대신 로그인 유도로 일원화한다.
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
