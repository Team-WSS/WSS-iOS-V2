//
//  NovelNotificationListViewModel.swift
//  SettingFeature
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import NotificationDomain
import Logger

/// 완결 알림/휴재 복귀 알림 목록 화면 공용 VM — `type`만 다르고 나머지 동작은 완전히 동일하다(#188).
@MainActor
@Observable
final class NovelNotificationListViewModel {

    // MARK: - State

    struct State {
        var subscriptions: [NovelNotificationSubscription] = []
        /// 툴바 "수정"을 눌러야 선택이 가능해진다(기본은 비편집 상태) — "삭제"로 라벨이 바뀌는 것도 이 값 기준.
        var isEditing = false
        var selectedNovelIDs: Set<NovelID> = []
        var isLoading = false
        var isLoadingMore = false
        var hasNextPage = false
        var isDeleting = false
        var presentedDeleteConfirmation = false
        var shouldDismiss = false
        /// 최초 로드 실패(에러 종류). 전체화면 `NetworkErrorView`에 넘겨 3분류 문구를 분기한다 — 삭제 실패와 분리한다.
        var loadError: RepositoryError?
        /// 삭제 실패(의미값). 토스트 표시용 — 화면은 그대로 두고 선택 상태도 유지한다.
        var toastError: NovelNotificationListError?
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호(Feature 공통 계약).
        var requiresAuthentication = false
    }

    /// 사용자에게 표시할 에러의 **의미값**. 카피·표현(토스트 타입)은 View가 결정한다.
    enum NovelNotificationListError: Equatable {
        case unknown
    }

    // MARK: - Action

    enum Action {
        case load
        case loadMore
        case beginEditing
        case toggleSelection(NovelID)
        case presentDeleteConfirmation
        case dismissDeleteConfirmation
        case confirmDelete
        case dismissToast
        case requestClose
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var loadMoreTask: Task<Void, Never>?
    @ObservationIgnored private var deleteTask: Task<Void, Never>?
    @ObservationIgnored private var nextSubscriptionID: SubscriptionID?
    @ObservationIgnored private var isClosing = false

    // MARK: - Dependency

    private let type: NovelNotificationType
    private let logger: Logger?

    // NotificationDomain
    private let loadSubscriptionsUseCase: LoadNovelNotificationSubscriptionsUseCase
    private let deleteSubscriptionsUseCase: DeleteNovelNotificationSubscriptionsUseCase

    // MARK: - Init

    init(
        type: NovelNotificationType,
        loadSubscriptionsUseCase: LoadNovelNotificationSubscriptionsUseCase,
        deleteSubscriptionsUseCase: DeleteNovelNotificationSubscriptionsUseCase,
        logger: Logger? = nil
    ) {
        self.type = type
        self.loadSubscriptionsUseCase = loadSubscriptionsUseCase
        self.deleteSubscriptionsUseCase = deleteSubscriptionsUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .loadMore:
            loadMore()
        case .beginEditing:
            state.isEditing = true
        case .toggleSelection(let novelID):
            toggleSelection(novelID)
        case .presentDeleteConfirmation:
            presentDeleteConfirmation()
        case .dismissDeleteConfirmation:
            state.presentedDeleteConfirmation = false
        case .confirmDelete:
            confirmDelete()
        case .dismissToast:
            state.toastError = nil
        case .requestClose:
            close()
        }
    }
}

// MARK: - Action Handling

private extension NovelNotificationListViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil, !isClosing else { return }
        state.isLoading = true
        state.loadError = nil
        loadTask = Task { await loadSubscriptions() }
    }

    /// 목록 마지막 행이 보일 때 View가 호출(무한스크롤). 다음 페이지가 없거나 이미 로딩 중이면 무시.
    /// 현재 페이지를 통째로 삭제해 목록이 비었을 때(`deleteSelectedSubscriptions`)도 이 경로로 재호출된다.
    func loadMore() {
        guard hasLoaded, state.hasNextPage, loadTask == nil, loadMoreTask == nil, !isClosing else { return }
        state.isLoadingMore = true
        loadMoreTask = Task { await loadMoreSubscriptions() }
    }

    func toggleSelection(_ novelID: NovelID) {
        guard state.isEditing else { return }
        if state.selectedNovelIDs.contains(novelID) {
            state.selectedNovelIDs.remove(novelID)
        } else {
            state.selectedNovelIDs.insert(novelID)
        }
    }

    func presentDeleteConfirmation() {
        guard !state.selectedNovelIDs.isEmpty, !isClosing else { return }
        state.presentedDeleteConfirmation = true
    }

    func confirmDelete() {
        guard !state.isDeleting, !isClosing else { return }
        state.presentedDeleteConfirmation = false
        state.isDeleting = true
        deleteTask = Task { await deleteSelectedSubscriptions() }
    }

    /// 뒤로가기 요청. 진행 중인 로드/삭제를 취소하고 닫기 신호만 View로 발화한다(`NovelDetailViewModel`과 동일 패턴).
    func close() {
        guard !isClosing else { return }
        isClosing = true
        loadTask?.cancel()
        loadMoreTask?.cancel()
        deleteTask?.cancel()
        state.shouldDismiss = true
    }
}

// MARK: - UseCase Handling

private extension NovelNotificationListViewModel {
    func loadSubscriptions() async {
        defer {
            loadTask = nil
            state.isLoading = false
        }

        do {
            let paged = try await loadSubscriptionsUseCase.execute(type: type, lastSubscriptionID: nil, size: 20)
            guard !Task.isCancelled else { return }
            state.subscriptions = paged.subscriptions
            state.hasNextPage = paged.isLoadable
            nextSubscriptionID = paged.nextSubscriptionID
            hasLoaded = true
        } catch {
            guard !Task.isCancelled else { return }
            presentLoadError(error)
        }
    }

    func loadMoreSubscriptions() async {
        defer {
            loadMoreTask = nil
            state.isLoadingMore = false
        }

        do {
            let paged = try await loadSubscriptionsUseCase.execute(type: type, lastSubscriptionID: nextSubscriptionID, size: 20)
            guard !Task.isCancelled else { return }
            state.subscriptions.append(contentsOf: paged.subscriptions)
            state.hasNextPage = paged.isLoadable
            nextSubscriptionID = paged.nextSubscriptionID
        } catch {
            guard !Task.isCancelled else { return }
            if routeToLoginIfAuthenticationRequired(error) { return }
            logger?.error("작품 알림 구독 목록 다음 페이지 조회 실패: \(String(describing: error))")
        }
    }

    func deleteSelectedSubscriptions() async {
        defer {
            deleteTask = nil
            state.isDeleting = false
        }

        let novelIDs = Array(state.selectedNovelIDs)
        do {
            try await deleteSubscriptionsUseCase.execute(type: type, novelIDs: novelIDs)
            guard !Task.isCancelled else { return }
            state.subscriptions.removeAll { novelIDs.contains($0.novelID) }
            state.selectedNovelIDs.removeAll()
            state.isEditing = false
            // 현재 로드된 페이지를 통째로 삭제한 경우 — 목록은 비었지만 서버엔 다음 페이지가 남아있을 수 있어
            // 그대로 두면 빈 상태(WSSEmptyView)로 잘못 보인다. 다음 페이지가 있으면 바로 이어서 불러온다.
            if state.subscriptions.isEmpty, state.hasNextPage {
                loadMore()
            }
        } catch {
            guard !Task.isCancelled else { return }
            presentToastError(error)
        }
    }
}

// MARK: - Error Mapping

private extension NovelNotificationListViewModel {
    func presentLoadError(_ error: Error) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("작품 알림 구독 목록 로드 실패: \(String(describing: error))")
        state.loadError = (error as? RepositoryError) ?? .unknown
    }

    func presentToastError(_ error: Error) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("작품 알림 구독 삭제 실패: \(String(describing: error))")
        state.toastError = .unknown
    }

    /// 인증 만료(`authenticationRequired`)면 로그인 라우팅 신호를 세우고 true 반환(Feature 공통 계약).
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
