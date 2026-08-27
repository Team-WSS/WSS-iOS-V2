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

        var requiresAuthentication = false
    }

    // MARK: - Action

    enum Action {
        case load
        case changeSortType(SortType)
        case toggleLike
        case menuTapped
        case dismissMenu
        case editTapped
        /// 수정 화면(로컬 push, `CollectionDetailView`가 소유)에서 돌아왔을 때 — 성공 콜백 없는
        /// 자기완결 dismiss 계약이라 성공/취소 구분 없이 무조건 다시 로드한다(`CollectionListView`의
        /// `reloadAfterDetail`과 동일 판단).
        case reloadAfterEdit
        case deleteTapped
        case dismissDeleteAlert
        case confirmDelete
        case dismissActionErrorToast
        case shareTapped
        /// 뒤로가기 버튼 탭 — `dismiss()` 직전에 View가 함께 호출한다. `.onDisappear`로는 못 쓴다
        /// — 이 화면은 "컬렉션 수정"을 같은 스택에 로컬 push하는데, push되는 순간 부모도
        /// `.onDisappear`가 발화해(SwiftUI 표준 동작) `isClosing`이 영구히 굳어버린다(실측 확인,
        /// 수정 복귀 후 재조회·정렬·좋아요·삭제 전부 무반응이 되는 회귀였다) — 그래서
        /// `NovelDetailViewModel.close()`처럼 **명시적 사용자 액션**으로만 세운다.
        case backTapped
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var likeTask: Task<Void, Never>?
    /// 화면이 닫히는 중 — 뒤로가기(`.backTapped`)나 삭제 성공이 세운다(아래 `close()`).
    @ObservationIgnored private var isClosing = false

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
            // 메뉴만 닫는다(delete와 대칭) — 실제 화면 전환(isEditPresented)은 View가 로컬 상태로
            // 소유한다("작품 추가"/"서재에서 추가"와 같은 위상, `CollectionFeature/CLAUDE.md` 참고).
            state.isMenuPresented = false
        case .reloadAfterEdit:
            reloadAfterEdit()
        case .deleteTapped:
            state.isMenuPresented = false
            state.isDeleteAlertPresented = true
        case .dismissDeleteAlert:
            state.isDeleteAlertPresented = false
        case .confirmDelete:
            confirmDelete()
        case .dismissActionErrorToast:
            state.hasActionError = false
        case .shareTapped:
            // TODO: - 공유하기(이번 범위 밖 — 공유 URL/딥링크 체계 없음)
            break
        case .backTapped:
            close()
        }
    }
}

// MARK: - Action Handling

private extension CollectionDetailViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil, !isClosing else { return }
        state.isLoading = true
        state.hasLoadError = false
        loadTask = Task { await loadDetail() }
    }

    /// 정렬 변경은 진입 1회 가드와 무관하게 매번 새로 조회한다("최신순"↔"오래된순" 토글, `WSSSortButton` 탭).
    func changeSortType(_ sortType: SortType) {
        guard loadTask == nil, !isClosing else { return }
        state.sortType = sortType
        state.isLoading = true
        state.hasLoadError = false
        loadTask = Task { await loadDetail() }
    }

    /// 수정 화면 복귀 재조회 — 진입 1회 가드(`hasLoaded`)를 우회해 강제로 다시 불러온다. 이미
    /// `state.detail`이 있는 상태라 View의 `isLoading && detail == nil` 오버레이 조건상 전면 로딩으로
    /// 덮이지 않는다(정렬 변경과 동일 UX, `CollectionDetailView`의 그 조건 그대로 재사용).
    func reloadAfterEdit() {
        guard loadTask == nil, !isClosing else { return }
        state.isLoading = true
        state.hasLoadError = false
        loadTask = Task { await loadDetail() }
    }

    /// 좋아요 토글. 정책(카운트 증감·음수 방지)은 엔티티 `CollectionDetail.toggleLike()`에 위임하고,
    /// UI에 낙관적으로 먼저 반영한 뒤 서버 동기화 실패 시 롤백한다(`UserPageFeature`의 피드 좋아요와 동일 패턴).
    func toggleLike() {
        guard likeTask == nil, !isClosing, var detail = state.detail else { return }
        let before = detail
        detail.toggleLike()
        state.detail = detail
        likeTask = Task { await syncLike(to: detail.isLiked, rollbackTo: before) }
    }

    func confirmDelete() {
        guard !state.isDeleting, !isClosing else { return }
        state.isDeleteAlertPresented = false
        state.isDeleting = true
        Task { await deleteCollection() }
    }

    /// 뒤로가기 — 진행 중인 로드/좋아요 동기화가 뒤늦게 완료되며 이미 떠난 화면의 state를 건드리지
    /// 않도록 막는다. 삭제(`confirmDelete`)는 취소하지 않는다 — 확인 알럿을 거친 명시적 요청이라
    /// 화면이 닫히는 도중이어도 서버 반영까지 끝까지 보낸다(`NovelReviewViewModel.close()`가 저장
    /// Task는 취소하지 않는 것과 동일 판단).
    func close() {
        guard !isClosing else { return }
        isClosing = true
        loadTask?.cancel()
        likeTask?.cancel()
    }
}

// MARK: - UseCase Handling

private extension CollectionDetailViewModel {
    func loadDetail() async {
        defer {
            loadTask = nil
            if !isClosing { state.isLoading = false }
        }

        do {
            let detail = try await loadCollectionDetailUseCase.execute(id: id, sortType: state.sortType)
            guard !isClosing, !Task.isCancelled else { return }
            state.detail = detail
            hasLoaded = true
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            if routeToLoginIfAuthenticationRequired(error) { return }
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
            guard !isClosing, !Task.isCancelled else { return }
            state.detail = before
            if routeToLoginIfAuthenticationRequired(error) { return }
            logger?.error("컬렉션 좋아요 동기화 실패: \(String(describing: error))")
        }
    }

    func deleteCollection() async {
        defer {
            if !isClosing { state.isDeleting = false }
        }
        do {
            try await deleteCollectionUseCase.execute(id: id)
            guard !isClosing, !Task.isCancelled else { return }
            // 삭제 성공도 뒤로가기와 마찬가지로 진짜 exit다 — 이후 View의 shouldDismiss→dismiss()
            // 사이 틈에 다른 액션(정렬 변경 등)이 끼어들지 않도록 여기서도 닫힘으로 표시한다.
            close()
            state.shouldDismiss = true
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            if routeToLoginIfAuthenticationRequired(error) { return }
            logger?.error("컬렉션 삭제 실패: \(String(describing: error))")
            state.hasActionError = true
        }
    }
}

// MARK: - Error Mapping

private extension CollectionDetailViewModel {
    /// push 후 dismiss되는 화면(탭 콘텐츠 아님)이라 `CollectionListViewModel`/`CreateCollectionViewModel`과
    /// 동일하게 1회성 신호로 충분 — `.consumeAuthenticationRequired` 같은 소진 처리가 필요 없다.
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
