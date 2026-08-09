//
//  LibraryViewModel.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import NovelDomain
import Logger

@MainActor
@Observable
final class LibraryViewModel {

    // MARK: - State

    struct State {
        var novels: [LibraryNovel] = []
        /// 필터 적용된 전체 작품 수 (헤더 "n개" 표기).
        var totalCount = 0
        var filter = MyLibraryFilter()
        /// 초기값 true — onAppear의 `.load`보다 첫 body 평가가 먼저라, false로 시작하면
        /// 로드 시작 전 한 프레임 동안 빈 상태/실패 뷰가 스친다. (NovelDetail 교훈)
        var isLoading = true
        /// 다음 페이지 로드 중 (하단 스피너용). 첫 페이지 로드는 `isLoading`.
        var isLoadingMore = false
        /// 첫 페이지 로드 실패 여부 — View가 "서재 비어있음"과 "로드 실패"를 구분해 그리기 위한 상태.
        /// (더보기 실패는 기존 목록을 유지하므로 토스트만 띄우고 이 값은 건드리지 않는다.)
        var loadFailed = false
        /// 필터 시트 키워드 탭에 보여줄, 내가 서재 작품들에 등록한 키워드 목록.
        var registeredKeywords: [Keyword] = []
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호.
        /// View가 `onChange`로 받은 뒤 **반드시 `.consumeAuthenticationRequired`로 내려야** 한다 —
        /// 서재는 탭 콘텐츠라 VM이 앱 세션 내내 살아서, true로 굳으면 2회차 만료가 조용히 삼켜진다.
        var requiresAuthentication = false
        /// 표시할 토스트(의미값). 표현(문구·스타일) 매핑은 View가 한다(얇은 ViewModel).
        /// 첫 페이지 로드 실패는 전면 실패 뷰(`loadFailed`)가 표현하므로 여기 없다.
        var presentedToast: LibraryToast?
    }

    /// 사용자에게 표시할 토스트의 **의미값**. 카피·표현은 View가 결정한다.
    enum LibraryToast: Equatable {
        case loadMoreFailed
        case keywordsLoadFailed
    }

    // MARK: - Action

    enum Action {
        case load
        case retry
        case loadMore
        case toggleInterestFilter
        case selectSortType(LibrarySortType)
        case applyFilter(MyLibraryFilter)
        case loadRegisteredKeywords
        case dismissToast
        case consumeAuthenticationRequired
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    // 1회 가드 플래그는 실패 고착을 막기 위해 **성공 시에만** 소진한다(NovelReview 교훈).
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var keywordsTask: Task<Void, Never>?
    /// 서버 발급 커서 — 다음 페이지 요청에 그대로 왕복한다. View가 볼 값이 아니라 State 밖.
    @ObservationIgnored private var nextCursor: String?
    @ObservationIgnored private var hasNext = true

    // MARK: - Dependency

    private let logger: Logger?

    // NovelDomain
    private let loadMyLibraryUseCase: LoadMyLibraryUseCase
    private let loadMyLibraryKeywordsUseCase: LoadMyLibraryKeywordsUseCase

    // MARK: - Init

    init(
        loadMyLibraryUseCase: LoadMyLibraryUseCase,
        loadMyLibraryKeywordsUseCase: LoadMyLibraryKeywordsUseCase,
        logger: Logger? = nil
    ) {
        self.loadMyLibraryUseCase = loadMyLibraryUseCase
        self.loadMyLibraryKeywordsUseCase = loadMyLibraryKeywordsUseCase
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
        case .toggleInterestFilter:
            toggleInterestFilter()
        case .selectSortType(let sortType):
            selectSortType(sortType)
        case .applyFilter(let filter):
            applyFilter(filter)
        case .loadRegisteredKeywords:
            loadRegisteredKeywords()
        case .dismissToast:
            state.presentedToast = nil
        case .consumeAuthenticationRequired:
            state.requiresAuthentication = false
        }
    }
}

// MARK: - Action Handling

private extension LibraryViewModel {

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

    /// 다음 페이지 로드. 커서는 직전 응답의 `nextCursor`를 그대로 왕복한다.
    func loadMore() {
        guard hasNext,
              loadTask == nil,
              !state.isLoading,
              let cursor = nextCursor else { return }
        state.isLoadingMore = true
        loadTask = Task { await loadPage(cursor: cursor) }
    }

    /// 관심 칩 토글 — 필터가 바뀌므로 목록을 처음부터 다시 로드한다.
    func toggleInterestFilter() {
        state.filter.toggleInterest()
        reloadFromScratch()
    }

    /// 정렬 선택(정렬 시트). 같은 값 재선택은 무시한다.
    func selectSortType(_ sortType: LibrarySortType) {
        guard state.filter.sortType != sortType else { return }
        state.filter.setSortType(sortType)
        reloadFromScratch()
    }

    /// 필터 시트 "작품 찾기" — 시트가 편집한 필터로 통째로 교체하고 다시 로드한다.
    /// (시트는 현재 필터의 복사본에서 시작하므로 관심·정렬도 보존된 채 돌아온다.)
    func applyFilter(_ filter: MyLibraryFilter) {
        state.filter = filter
        reloadFromScratch()
    }

    /// 필터 시트 키워드 탭 데이터 로드. 서재 등록 상태에 따라 변하므로 시트를 열 때마다 다시 불러온다.
    func loadRegisteredKeywords() {
        guard keywordsTask == nil else { return }
        keywordsTask = Task { await loadKeywords() }
    }

    /// 목록을 처음부터 다시 로드한다(첫 로드·재시도·필터/정렬 변경 공통).
    /// 진행 중이던 로드는 **취소만** 하면 된다 — 취소된 로드는 상태를 일절 건드리지 않으므로
    /// 늦게 도착해도 새 목록을 덮지 않는다(`loadPage` 주석 참고).
    func reloadFromScratch() {
        loadTask?.cancel()
        nextCursor = nil
        hasNext = true
        state.novels = []
        state.totalCount = 0
        state.isLoading = true
        state.isLoadingMore = false
        state.loadFailed = false
        loadTask = Task { await loadPage(cursor: nil) }
    }
}

// MARK: - UseCase Handling

private extension LibraryViewModel {

    /// 서재 페이지 로드. `cursor == nil`이면 첫 페이지(목록 교체), 아니면 다음 페이지(append).
    ///
    /// ⚠️ **취소된 로드는 상태를 일절 건드리지 않는다 — 그래서 `defer`를 쓰지 않는다.**
    /// `defer`는 취소 여부와 무관하게 실행되므로, 필터를 연달아 바꿔 이전 로드가 취소된 뒤 뒤늦게 깨어나면
    /// **새 로드의 `loadTask`를 지우고 로딩 플래그를 꺼버린다**(중복 요청 가드가 풀리고 스피너가 사라진다).
    /// 정리를 성공·실패 경로로 옮기면 취소된 로드는 자연히 아무것도 안 하므로,
    /// "지금 유효한 로드인가"를 따로 추적할 필요가 없다(세대 카운터를 걷어낸 이유).
    func loadPage(cursor: String?) async {
        do {
            let (page, totalCount) = try await loadMyLibraryUseCase.execute(filter: state.filter, cursor: cursor)
            guard !Task.isCancelled else { return }
            if cursor == nil {
                state.novels = page.items
                hasLoaded = true
            } else {
                state.novels.append(contentsOf: page.items)
            }
            state.totalCount = totalCount
            nextCursor = page.nextCursor
            hasNext = page.hasNext
            state.loadFailed = false
            finishLoading()
        } catch {
            guard !Task.isCancelled else { return }
            // 인증 만료는 실패 뷰/토스트 대신 로그인 유도로 일원화 — 실패 플래그보다 먼저 거른다.
            if routeToLoginIfAuthenticationRequired(error) {
                finishLoading()
                return
            }
            if cursor == nil {
                // 첫 페이지 실패는 전면 실패 뷰가 표현한다 — 토스트까지 띄우면 에러 시그널이 이중화된다.
                state.loadFailed = true
                logger?.error("Library 실패(load): \(String(describing: error))")
            } else {
                presentError(error, as: .loadMoreFailed)
            }
            finishLoading()
        }
    }

    /// 로딩 종료 — **취소되지 않은 로드만** 호출한다(취소된 로드가 부르면 위 주석의 사고가 난다).
    func finishLoading() {
        loadTask = nil
        state.isLoading = false
        state.isLoadingMore = false
    }

    /// 서재 등록 키워드 로드(필터 시트 키워드 탭).
    func loadKeywords() async {
        defer { keywordsTask = nil }
        do {
            let keywords = try await loadMyLibraryKeywordsUseCase.execute()
            guard !Task.isCancelled else { return }
            state.registeredKeywords = keywords
        } catch {
            guard !Task.isCancelled else { return }
            presentError(error, as: .keywordsLoadFailed)
        }
    }
}

// MARK: - Error Mapping

private extension LibraryViewModel {

    /// Repository 에러를 발생 맥락의 의미 토스트로 변환한다. 원인은 로그로 남긴다.
    func presentError(_ error: Error, as presented: LibraryToast) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("Library 실패(\(presented)): \(String(describing: error))")
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
