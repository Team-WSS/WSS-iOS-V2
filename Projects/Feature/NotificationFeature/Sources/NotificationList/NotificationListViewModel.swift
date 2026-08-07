//
//  NotificationListViewModel.swift
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
final class NotificationListViewModel {

    // MARK: - State

    struct State {
        var items: [NotificationItem] = []
        /// 초기값 true — onAppear의 `.load`보다 첫 body 평가가 먼저라, false로 시작하면
        /// 로드 시작 전 한 프레임 동안 빈 상태가 스친다. (Library·NovelDetail 교훈)
        var isLoading = true
        /// 다음 페이지 로드 중 (하단 스피너용). 첫 페이지 로드는 `isLoading`.
        var isLoadingMore = false
        /// 첫 페이지 로드 실패 여부 — View가 "알림 없음"과 "로드 실패"를 구분해 그리기 위한 상태.
        /// (더보기 실패는 기존 목록을 유지하므로 토스트만 띄우고 이 값은 건드리지 않는다.)
        var loadFailed = false
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호.
        var requiresAuthentication = false
        /// 표시할 토스트(의미값). 표현(문구·스타일) 매핑은 View가 한다(얇은 ViewModel).
        /// 첫 페이지 로드 실패는 전면 실패 뷰(`loadFailed`)가 표현하므로 여기 없다.
        var presentedToast: NotificationListToast?
    }

    /// 사용자에게 표시할 토스트의 **의미값**. 카피·표현은 View가 결정한다.
    enum NotificationListToast: Equatable {
        case loadMoreFailed
    }

    // MARK: - Action

    enum Action {
        case load
        case retry
        case loadMore
        /// 셀 탭 — 읽음 처리를 요청한다. 딥링크에 따른 화면 전환은 View가 상위 콜백으로 위임한다.
        case selectNotification(NotificationItem)
        case dismissToast
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    /// 1회 가드 플래그는 실패 고착을 막기 위해 **성공 시에만** 소진한다(NovelReview 교훈).
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    /// 커서 페이지네이션의 마지막 항목 ID — 다음 페이지 요청에 그대로 넘긴다. View가 볼 값이 아니라 State 밖.
    @ObservationIgnored private var lastNotificationID: NotificationID?
    /// 서버가 내려주는 `isLoadable` — 더 불러올 페이지가 있는지.
    @ObservationIgnored private var isLoadable = true
    /// 이미 읽음 처리를 보낸 알림 — 같은 셀을 반복 탭해도 서버 호출을 한 번만 보낸다.
    @ObservationIgnored private var markedAsReadIDs: Set<NotificationID> = []

    private static let pageSize = 20

    // MARK: - Dependency

    private let logger: Logger?

    // NotificationDomain
    private let loadPagedNotificationsUseCase: LoadPagedNotificationsUseCase
    private let markNotificationAsReadUseCase: MarkNotificationAsReadUseCase

    // MARK: - Init

    init(
        loadPagedNotificationsUseCase: LoadPagedNotificationsUseCase,
        markNotificationAsReadUseCase: MarkNotificationAsReadUseCase,
        logger: Logger? = nil
    ) {
        self.loadPagedNotificationsUseCase = loadPagedNotificationsUseCase
        self.markNotificationAsReadUseCase = markNotificationAsReadUseCase
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
        case .loadMore:
            loadMore()
        case .selectNotification(let item):
            selectNotification(item)
        case .dismissToast:
            state.presentedToast = nil
        }
    }
}

// MARK: - Action Handling

private extension NotificationListViewModel {

    /// 진입 시 첫 페이지 로드. onAppear는 재진입마다 불리므로 성공 후에는 다시 로드하지 않되,
    /// 실패는 가드를 소진하지 않아 재진입 시 재시도가 열려 있다.
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        reloadFromScratch()
    }

    /// 전면 실패 뷰의 재시도.
    func retry() {
        guard loadTask == nil else { return }
        reloadFromScratch()
    }

    /// 다음 페이지 로드. 커서는 지금까지 받은 마지막 알림 ID다.
    func loadMore() {
        guard isLoadable,
              loadTask == nil,
              !state.isLoading,
              let cursor = lastNotificationID else { return }
        state.isLoadingMore = true
        loadTask = Task { await loadPage(lastNotificationID: cursor) }
    }

    /// 셀 탭 — 읽음 상태를 낙관 반영하고 서버에 알린다(화면 전환은 View 몫).
    func selectNotification(_ item: NotificationItem) {
        markAsRead(id: item.id)
    }

    /// 목록을 처음부터 다시 로드한다(첫 로드·재시도 공통).
    func reloadFromScratch() {
        loadTask?.cancel()
        lastNotificationID = nil
        isLoadable = true
        state.items = []
        state.isLoading = true
        state.isLoadingMore = false
        state.loadFailed = false
        loadTask = Task { await loadPage(lastNotificationID: nil) }
    }
}

// MARK: - UseCase Handling

private extension NotificationListViewModel {

    /// 알림 페이지 로드. `lastNotificationID == nil`이면 첫 페이지(목록 교체), 아니면 다음 페이지(append).
    func loadPage(lastNotificationID cursor: NotificationID?) async {
        defer {
            loadTask = nil
            state.isLoading = false
            state.isLoadingMore = false
        }
        do {
            let page = try await loadPagedNotificationsUseCase.execute(
                lastNotificationID: cursor,
                size: Self.pageSize
            )
            guard !Task.isCancelled else { return }
            if cursor == nil {
                state.items = page.items
                hasLoaded = true
            } else {
                state.items.append(contentsOf: page.items)
            }
            lastNotificationID = page.items.last?.id ?? cursor
            isLoadable = page.isLoadable
            state.loadFailed = false
        } catch {
            guard !Task.isCancelled else { return }
            // 인증 만료는 실패 뷰/토스트 대신 로그인 유도로 일원화 — 실패 플래그보다 먼저 거른다.
            if routeToLoginIfAuthenticationRequired(error) { return }
            if cursor == nil {
                // 첫 페이지 실패는 전면 실패 뷰가 표현한다 — 토스트까지 띄우면 에러 시그널이 이중화된다.
                state.loadFailed = true
                logger?.error("NotificationList 실패(load): \(String(describing: error))")
            } else {
                presentError(error, as: .loadMoreFailed)
            }
        }
    }

    /// 읽음 처리. 목록을 즉시 갱신(낙관)하고 서버 호출은 뒤따른다.
    func markAsRead(id: NotificationID) {
        guard !markedAsReadIDs.contains(id) else { return }
        markedAsReadIDs.insert(id)
        applyReadState(id: id)
        Task { await sendMarkAsRead(id: id) }
    }

    func sendMarkAsRead(id: NotificationID) async {
        do {
            try await markNotificationAsReadUseCase.execute(id: id)
        } catch {
            if routeToLoginIfAuthenticationRequired(error) { return }
            logger?.error("NotificationList 실패(markAsRead): \(String(describing: error))")
        }
    }

    /// 해당 알림을 읽음으로 교체한다. `NotificationItem`은 전 프로퍼티가 let이라 새 값으로 갈아 끼운다.
    func applyReadState(id: NotificationID) {
        guard let index = state.items.firstIndex(where: { $0.id == id }),
              !state.items[index].isRead else { return }
        let item = state.items[index]
        state.items[index] = NotificationItem(
            id: item.id,
            iconURL: item.iconURL,
            title: item.title,
            body: item.body,
            createdAtText: item.createdAtText,
            isRead: true,
            deeplink: item.deeplink
        )
    }
}

// MARK: - Error Mapping

private extension NotificationListViewModel {

    /// Repository 에러를 발생 맥락의 의미 토스트로 변환한다. 원인은 로그로 남긴다.
    func presentError(_ error: Error, as presented: NotificationListToast) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("NotificationList 실패(\(presented)): \(String(describing: error))")
        if state.presentedToast != nil { return }
        state.presentedToast = presented
    }

    /// 인증 만료(`authenticationRequired`)면 로그인 라우팅 신호를 세우고 true 반환.
    /// 세션이 죽은 상황이라 개별 실패 토스트 대신 로그인 유도로 일원화한다.
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
