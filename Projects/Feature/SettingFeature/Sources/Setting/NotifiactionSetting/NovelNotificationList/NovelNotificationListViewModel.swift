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
        /// 최초 로드 실패(의미값). 전체화면 `NetworkErrorView` 표시용 — 삭제 실패와 분리한다.
        var loadError: NovelNotificationListError?
        /// 삭제 실패(의미값). 토스트 표시용 — 화면은 그대로 두고 선택 상태도 유지한다.
        var toastError: NovelNotificationListError?
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
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var loadMoreTask: Task<Void, Never>?
    @ObservationIgnored private var nextSubscriptionID: SubscriptionID?

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
        }
    }
}

// MARK: - Action Handling

private extension NovelNotificationListViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        state.isLoading = true
        state.loadError = nil
        loadTask = Task { await loadSubscriptions() }
    }

    /// 목록 마지막 행이 보일 때 View가 호출(무한스크롤). 다음 페이지가 없거나 이미 로딩 중이면 무시.
    func loadMore() {
        guard hasLoaded, state.hasNextPage, loadTask == nil, loadMoreTask == nil else { return }
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
        guard !state.selectedNovelIDs.isEmpty else { return }
        state.presentedDeleteConfirmation = true
    }

    func confirmDelete() {
        guard !state.isDeleting else { return }
        state.presentedDeleteConfirmation = false
        state.isDeleting = true
        Task { await deleteSelectedSubscriptions() }
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
            logger?.error("작품 알림 구독 목록 다음 페이지 조회 실패: \(String(describing: error))")
        }
    }

    func deleteSelectedSubscriptions() async {
        defer { state.isDeleting = false }

        let novelIDs = Array(state.selectedNovelIDs)
        do {
            try await deleteSubscriptionsUseCase.execute(type: type, novelIDs: novelIDs)
            state.subscriptions.removeAll { novelIDs.contains($0.novelID) }
            state.selectedNovelIDs.removeAll()
            state.isEditing = false
        } catch {
            presentToastError(error)
        }
    }
}

// MARK: - Error Mapping

private extension NovelNotificationListViewModel {
    func presentLoadError(_ error: Error) {
        logger?.error("작품 알림 구독 목록 로드 실패: \(String(describing: error))")
        state.loadError = .unknown
    }

    func presentToastError(_ error: Error) {
        logger?.error("작품 알림 구독 삭제 실패: \(String(describing: error))")
        state.toastError = .unknown
    }
}
