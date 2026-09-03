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
        /// 셀 탭 — 읽음 처리를 요청한다(서버 호출 여부는 딥링크에 따라 갈린다).
        /// 딥링크에 따른 화면 전환은 View가 상위 콜백으로 위임한다.
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
    /// **서버에** 읽음 처리를 보낸 알림 — 같은 셀을 반복 탭해도 호출을 한 번만 보낸다.
    /// 상세 딥링크 알림은 서버가 상세 조회로 읽음 처리하므로 여기 들어오지 않는다(낙관 반영만 한다).
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

    /// 진입/재진입 로드. onAppear는 재진입마다 불린다(#236, push 재진입 재조회 복원 — V1 parity).
    /// - **첫 로드**(`!hasLoaded`): 로딩 뷰와 함께 처음부터 로드. 실패는 가드를 소진하지 않아 재시도가 열려 있다.
    /// - **재진입**(`hasLoaded`): 스피너·목록 비움 없이 **조용히 첫 페이지를 재조회**해 목록을 교체한다 —
    ///   상세/피드/작품에서 복귀하는 사이 서버에서 바뀐 것(새 알림·다른 기기 읽음)을 반영하기 위함.
    ///   실패해도 기존 화면을 그대로 둔다(백그라운드 갱신이므로 — `NovelDetailViewModel.load` 정본).
    ///   ⚠️ 재조회 성공은 목록을 첫 페이지로 되돌린다(페이지네이션 리셋) — 깊이 스크롤한 채 복귀하는
    ///   드문 경우 스크롤이 위로 당겨질 수 있는 감수(V1은 아예 로딩뷰로 비우고 처음부터였다).
    func load() {
        guard loadTask == nil else { return }
        if hasLoaded {
            loadTask = Task { await loadPage(lastNotificationID: nil, isSilentRefresh: true) }
        } else {
            reloadFromScratch()
        }
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

    /// 셀 탭 — 읽음 상태를 낙관 반영하고, **명시 호출이 필요한 알림만** 서버에 알린다(화면 전환은 View 몫).
    /// 목록 표시는 딥링크와 무관하게 전부 즉시 읽음으로 바뀐다 — 갈리는 건 서버 호출 여부뿐이다.
    func selectNotification(_ item: NotificationItem) {
        applyReadState(id: item.id)
        // 케이스를 전부 나열한다 — 딥링크가 늘면 컴파일러가 여기를 짚어 정책을 다시 정하게 한다.
        switch item.deeplink {
        case .notificationDetail:
            // 알림 상세 조회(GET /notifications/{id})는 **서버가 조회와 동시에 읽음 처리까지** 한다
            // → read를 또 보내면 같은 일을 두 번 시키는 셈이라 생략한다. (→ NotificationData/CLAUDE.md)
            break
        case .feedDetail, .novelDetail, .unknown, .none:
            // 상세 API를 타지 않는 경로 — 여기서 보내지 않으면 그 알림은 영영 미읽음으로 남는다.
            markAsReadOnServer(id: item.id)
        }
    }

    /// 읽음 처리를 서버에 알린다(낙관 반영은 호출자가 이미 끝냈다).
    /// 실패해도 롤백하지 않는다 — 이유는 모듈 CLAUDE.md의 화면 동작 계약 참고.
    func markAsReadOnServer(id: NotificationID) {
        guard !markedAsReadIDs.contains(id) else { return }
        markedAsReadIDs.insert(id)
        Task { await sendMarkAsRead(id: id) }
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

    /// 목록을 처음부터 다시 로드한다(첫 로드·재시도 공통).
    /// **진행 중인 로드를 취소하지 않는다** — 두 호출자(`load`·`retry`)가 모두 `loadTask == nil`을 선행 확인하므로
    /// 이 함수가 불릴 때 인플라이트 요청이 없다.
    /// 재로드 경로가 늘면(당겨서 새로고침·"전체 읽음" 등) `loadTask?.cancel()`을 넣는 **동시에 `loadPage`의 `defer`를
    /// 걷어내고 정리를 성공·실패 경로로 옮겨야 한다** — `defer`는 취소 여부와 무관하게 실행돼, 취소된 옛 로드가
    /// 새 로드의 `loadTask`를 지우고 로딩 플래그를 꺼버린다. 그 형태는 서재(`LibraryViewModel`)가 정본이다.
    /// (그래서 `loadPage`의 `guard !Task.isCancelled`는 **지금은 발동하지 않는다** — 취소하는 곳이 없어서다.
    /// 위 경로가 생길 때 필요한 자리라 남겨둔 것이니 "죽은 코드"로 지우지 말 것.)
    func reloadFromScratch() {
        lastNotificationID = nil
        isLoadable = true
        // 읽음 처리 기록도 함께 비운다 — 목록을 새로 받으면 읽음 여부는 서버 값이 정본이라,
        // 남겨두면 이전에 실패했던 알림을 다시 탭해도 재요청이 스킵된다.
        markedAsReadIDs = []
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
    /// `isSilentRefresh`는 재진입의 조용한 재조회(#236) — 성공 처리는 첫 페이지와 같되(목록 교체 + 커서 리셋),
    /// 실패해도 화면을 실패 뷰로 덮지 않는다.
    func loadPage(lastNotificationID cursor: NotificationID?, isSilentRefresh: Bool = false) async {
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
                // 재조회로 목록을 새로 받으면 읽음 여부는 서버 값이 정본 — 이전 방문의 전송 기록을
                // 비워야 그때 실패했던 알림을 다시 탭했을 때 재요청이 스킵되지 않는다
                // (`reloadFromScratch`가 로드 전에 비우는 것과 같은 이유, 이쪽은 성공 시에만).
                if isSilentRefresh { markedAsReadIDs = [] }
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
            if isSilentRefresh {
                // 조용한 재조회 실패는 기존 화면을 그대로 둔다 — 실패 뷰로 덮으면 멀쩡히 보고 있던
                // 목록이 사라진다(백그라운드 갱신 실패는 알리지 않는 NovelDetail 계약과 동일).
                logger?.error("NotificationList 실패(silentRefresh): \(String(describing: error))")
            } else if cursor == nil {
                // 첫 페이지 실패는 전면 실패 뷰가 표현한다 — 토스트까지 띄우면 에러 시그널이 이중화된다.
                state.loadFailed = true
                logger?.error("NotificationList 실패(load): \(String(describing: error))")
            } else {
                presentError(error, as: .loadMoreFailed)
            }
        }
    }

    /// 읽음 처리를 서버에 알린다. 실패해도 화면은 읽음인 채로 둔다(모듈 CLAUDE.md의 화면 동작 계약).
    func sendMarkAsRead(id: NotificationID) async {
        do {
            try await markNotificationAsReadUseCase.execute(id: id)
        } catch {
            if routeToLoginIfAuthenticationRequired(error) { return }
            logger?.error("NotificationList 실패(markAsRead): \(String(describing: error))")
        }
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
