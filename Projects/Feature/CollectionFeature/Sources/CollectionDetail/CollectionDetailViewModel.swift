//
//  CollectionDetailViewModel.swift
//  CollectionFeature
//
//  Created by Guryss on 8/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import CollectionDomain
import Logger

@MainActor
@Observable
final class CollectionDetailViewModel {

    // MARK: - State

    struct State {
        var detail: CollectionDetail?
        var sortType: SortType = .recent
        var isLoading = false
        var hasLoadError = false

        /// 더보기 드롭다운(수정/삭제) 표시 여부 — `detail.isMine`일 때만 화면에 진입점 자체가 있다.
        var isMenuPresented = false
        var isDeleteAlertPresented = false
        var isDeleting = false
        /// 삭제 성공 신호. View가 `onChange`로 소비해 dismiss한다(`UserPageFeature`의 차단 성공과 동일 패턴)
        /// — 삭제된 컬렉션은 더 볼 수 없어 화면에 남아있을 이유가 없다.
        var shouldDismiss = false

        /// 좋아요·삭제 실패 공통 에러 토스트 — 둘 다 같은 카피(`WSSToastType.unknownError`)라 하나로 묶는다.
        var hasActionError = false
    }

    // MARK: - Action

    enum Action {
        case load
        case changeSortType(SortType)
        case toggleLike
        case menuTapped
        case dismissMenu
        case editTapped
        case deleteTapped
        case dismissDeleteAlert
        case confirmDelete
        case dismissActionErrorToast
        case novelTapped(NovelID)
        case shareTapped
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var likeTask: Task<Void, Never>?

    // MARK: - Dependency

    private let id: CollectionID
    private let logger: Logger?

    // CollectionDomain
    private let loadCollectionDetailUseCase: LoadCollectionDetailUseCase
    private let collectionLikeUseCase: CollectionLikeUseCase
    private let deleteCollectionUseCase: DeleteCollectionUseCase

    // MARK: - Init

    init(
        id: CollectionID,
        loadCollectionDetailUseCase: LoadCollectionDetailUseCase,
        collectionLikeUseCase: CollectionLikeUseCase,
        deleteCollectionUseCase: DeleteCollectionUseCase,
        logger: Logger? = nil
    ) {
        self.id = id
        self.loadCollectionDetailUseCase = loadCollectionDetailUseCase
        self.collectionLikeUseCase = collectionLikeUseCase
        self.deleteCollectionUseCase = deleteCollectionUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .changeSortType(let sortType):
            changeSortType(sortType)
        case .toggleLike:
            toggleLike()
        case .menuTapped:
            state.isMenuPresented.toggle()
        case .dismissMenu:
            state.isMenuPresented = false
        case .editTapped:
            // TODO: - 컬렉션 수정 화면으로 이동(이번 범위 밖 — 편집 화면은 별도 작업)
            logger?.info("컬렉션 수정 탭됨(미구현)")
        case .deleteTapped:
            state.isMenuPresented = false
            state.isDeleteAlertPresented = true
        case .dismissDeleteAlert:
            state.isDeleteAlertPresented = false
        case .confirmDelete:
            confirmDelete()
        case .dismissActionErrorToast:
            state.hasActionError = false
        case .novelTapped:
            // TODO: - 작품 상세로 이동(이번 범위 밖 — NovelDetailFeature와는 서로 import 불가, App 콜백 필요)
            break
        case .shareTapped:
            // TODO: - 공유하기(이번 범위 밖 — 공유 URL/딥링크 체계 없음)
            break
        }
    }
}

// MARK: - Action Handling

private extension CollectionDetailViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        state.isLoading = true
        state.hasLoadError = false
        loadTask = Task { await loadDetail() }
    }

    /// 정렬 변경은 진입 1회 가드와 무관하게 매번 새로 조회한다("최신순"↔"오래된순" 토글, `WSSSortButton` 탭).
    func changeSortType(_ sortType: SortType) {
        guard loadTask == nil else { return }
        state.sortType = sortType
        state.isLoading = true
        state.hasLoadError = false
        loadTask = Task { await loadDetail() }
    }

    /// 좋아요 토글. 정책(카운트 증감·음수 방지)은 엔티티 `CollectionDetail.toggleLike()`에 위임하고,
    /// UI에 낙관적으로 먼저 반영한 뒤 서버 동기화 실패 시 롤백한다(`UserPageFeature`의 피드 좋아요와 동일 패턴).
    func toggleLike() {
        guard likeTask == nil, var detail = state.detail else { return }
        let before = detail
        detail.toggleLike()
        state.detail = detail
        likeTask = Task { await syncLike(to: detail.isLiked, rollbackTo: before) }
    }

    func confirmDelete() {
        guard !state.isDeleting else { return }
        state.isDeleteAlertPresented = false
        state.isDeleting = true
        Task { await deleteCollection() }
    }
}

// MARK: - UseCase Handling

private extension CollectionDetailViewModel {
    func loadDetail() async {
        defer {
            loadTask = nil
            state.isLoading = false
        }

        do {
            state.detail = try await loadCollectionDetailUseCase.execute(id: id, sortType: state.sortType)
            hasLoaded = true
        } catch {
            logger?.error("컬렉션 상세 로드 실패: \(String(describing: error))")
            state.hasLoadError = true
        }
    }

    func syncLike(to isLiked: Bool, rollbackTo before: CollectionDetail) async {
        defer { likeTask = nil }
        do {
            if isLiked {
                try await collectionLikeUseCase.like(id: id)
            } else {
                try await collectionLikeUseCase.unlike(id: id)
            }
        } catch {
            state.detail = before
            logger?.error("컬렉션 좋아요 동기화 실패: \(String(describing: error))")
        }
    }

    func deleteCollection() async {
        defer { state.isDeleting = false }
        do {
            try await deleteCollectionUseCase.execute(id: id)
            state.shouldDismiss = true
        } catch {
            logger?.error("컬렉션 삭제 실패: \(String(describing: error))")
            state.hasActionError = true
        }
    }
}
