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
        ///
        /// ⚠️ **재진입 갱신은 이 값을 세우지 않는다** — 세우면 돌아올 때마다 이미 그린 목록이
        /// 로딩 뷰로 갈아치워져 스크롤 위치가 초기화된다(홈이 `isInitialLoading`으로 겪은 것과 같은 문제).
        var isLoading = true
        /// 다음 페이지 로드 중 (하단 스피너용). 첫 페이지 로드는 `isLoading`.
        var isLoadingMore = false
        /// 목록 로드 실패 여부(첫 페이지·더보기·갱신 **공통**) — 목록 자리를 전면 실패 뷰로 대체할지 가른다.
        /// ⚠️ 더보기 실패를 여기서 빼고 토스트로 가르지 말 것 — 토스트는 사라지면 재시도 경로가 없어
        /// 하단에서 페이지네이션이 멈춘 채 갇힌다(#195 실측). 규칙 정본: Feature CLAUDE.md "로드 실패 표현 계약".
        var loadFailed = false
        /// 필터 시트 키워드 탭에 보여줄, 내가 서재 작품들에 등록한 키워드 목록.
        var registeredKeywords: [Keyword] = []
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호.
        /// View가 `onChange`로 받은 뒤 **반드시 `.consumeAuthenticationRequired`로 내려야** 한다 —
        /// 서재는 탭 콘텐츠라 VM이 앱 세션 내내 살아서, true로 굳으면 2회차 만료가 조용히 삼켜진다.
        var requiresAuthentication = false
        /// 표시할 토스트(의미값). 표현(문구·스타일) 매핑은 View가 한다(얇은 ViewModel).
        /// 목록 로드 실패(첫 페이지·더보기·갱신)는 전면 실패 뷰(`loadFailed`)가 표현하므로 여기 없다.
        var presentedToast: LibraryToast?
    }

    /// 사용자에게 표시할 토스트의 **의미값**. 카피·표현은 View가 결정한다.
    /// 남은 토스트는 **부수 데이터 실패 하나뿐**이다 — 목록을 세우는 로드(첫 페이지·더보기·갱신)는
    /// 전부 전면 실패 뷰가 표현한다. 키워드는 필터 시트의 칩 데이터라 주 콘텐츠가 아니고,
    /// 시트가 떠 있는 동안 뒤 화면을 덮을 수도 없어서 토스트가 맞다.
    enum LibraryToast: Equatable {
        case keywordsLoadFailed
    }

    /// 목록 로드의 성격. **시작 표시·결과 반영·실패 표현이 전부 여기서 갈린다.**
    /// `cursor == nil`로 "첫 페이지"를 판단하던 걸 대체한다 — 갱신도 커서가 nil이라 그 기준으론 구분되지 않는다.
    fileprivate enum LoadKind {
        /// 첫 진입·재시도·필터/정렬 변경 — 전면 로딩 + 목록 교체.
        case reload
        /// 다음 페이지 — 하단 스피너 + append.
        case more(cursor: String)
        /// 재진입 갱신 — 표시 변화 없이 목록 교체.
        case refresh

        /// 로그용 라벨. 연관값(커서)을 빼서 서버 커서 원문이 로그에 남지 않게 한다.
        var logLabel: String {
            switch self {
            case .reload:  "첫 로드"
            case .more:    "더보기"
            case .refresh: "갱신"
            }
        }
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

    /// 지금 화면에 그릴 목록이 서 있는지 — 진입 시 "첫 로드냐 갱신이냐"를 가른다.
    /// ⚠️ **`state.novels`로 판단하지 말 것** — 갱신이 실패해도 배열엔 직전 성공 목록이 남아 있어서,
    /// 실패 뷰에서 재시도할 때 로딩 대신 옛 목록이 잠깐 되살아났다 다시 실패 뷰로 튄다(홈 실측).
    @ObservationIgnored private var hasLoadedContent = false
    /// 진행 중인 목록 로드. ⚠️ **로드는 항상 이 한 슬롯에만 산다** — "무효해진 로드 == 취소된 로드"라는
    /// 등식이 여기서 나오고, 그 등식이 세대 카운터를 대신한다(`loadPage` 주석).
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
    /// 필터·정렬 로컬 영속화(#221) — 앱 재실행을 넘겨 마지막 상태를 복원한다.
    private let loadMyLibraryFilterUseCase: LoadMyLibraryFilterUseCase
    private let saveMyLibraryFilterUseCase: SaveMyLibraryFilterUseCase

    // MARK: - Init

    init(
        loadMyLibraryUseCase: LoadMyLibraryUseCase,
        loadMyLibraryKeywordsUseCase: LoadMyLibraryKeywordsUseCase,
        loadMyLibraryFilterUseCase: LoadMyLibraryFilterUseCase,
        saveMyLibraryFilterUseCase: SaveMyLibraryFilterUseCase,
        logger: Logger? = nil
    ) {
        self.loadMyLibraryUseCase = loadMyLibraryUseCase
        self.loadMyLibraryKeywordsUseCase = loadMyLibraryKeywordsUseCase
        self.loadMyLibraryFilterUseCase = loadMyLibraryFilterUseCase
        self.saveMyLibraryFilterUseCase = saveMyLibraryFilterUseCase
        self.logger = logger
        // ⚠️ 복원은 **동기**로 여기서 한다 — 첫 `.load`(onAppear)보다 먼저 필터가 서 있어야
        // 첫 조회가 복원된 필터로 나간다(비동기로 복원하면 한 프레임 기본 필터로 로드가 새어 나간다).
        // 저장된 게 없으면 기본 필터로 시작.
        self.state = State(filter: loadMyLibraryFilterUseCase.execute() ?? MyLibraryFilter())
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

    /// 진입·재진입 공통(`onAppear`). 아직 보여줄 목록이 없으면 첫 로드, 있으면 **갱신**이다.
    ///
    /// ⚠️ **"최초 1회" 가드를 두지 않는 것이 의도다** — 작품 상세에서 별점·읽기상태를 바꾸고 돌아오거나
    /// 밖에서 작품을 등록하면 서재가 그 자리에서 최신이어야 한다(구 WSSiOS도 `viewWillAppear`마다 다시 불렀다).
    func load() {
        // 진행 중인 로드가 있으면 아무것도 하지 않는다 — 첫 로드면 중복 요청이고,
        // 갱신이면 사용자가 방금 시킨 로드(필터 변경 등)를 덮을 이유가 없다.
        guard loadTask == nil else { return }

        guard hasLoadedContent else {
            reloadFromScratch()
            return
        }
        loadTask = Task { await loadPage(.refresh) }
    }

    /// 전면 실패 뷰의 재시도.
    func retry() {
        guard loadTask == nil else { return }
        reloadFromScratch()
    }

    /// 다음 페이지 로드. 커서는 직전 응답의 `nextCursor`를 그대로 왕복한다.
    func loadMore() {
        guard hasNext, loadTask == nil, !state.isLoading, let cursor = nextCursor else { return }
        state.isLoadingMore = true
        loadTask = Task { await loadPage(.more(cursor: cursor)) }
    }

    /// 관심 칩 토글 — 필터가 바뀌므로 목록을 처음부터 다시 로드한다.
    func toggleInterestFilter() {
        state.filter.toggleInterest()
        persistFilter()
        reloadFromScratch()
    }

    /// 정렬 선택(정렬 시트). 같은 값 재선택은 무시한다.
    func selectSortType(_ sortType: LibrarySortType) {
        guard state.filter.sortType != sortType else { return }
        state.filter.setSortType(sortType)
        persistFilter()
        reloadFromScratch()
    }

    /// 필터 시트 "작품 찾기" — 시트가 편집한 필터로 통째로 교체하고 다시 로드한다.
    /// (시트는 현재 필터의 복사본에서 시작하므로 관심·정렬도 보존된 채 돌아온다.)
    func applyFilter(_ filter: MyLibraryFilter) {
        state.filter = filter
        persistFilter()
        reloadFromScratch()
    }

    /// 현재 필터·정렬을 로컬에 저장한다(#221). 필터·정렬이 바뀌는 **모든** 경로(관심·정렬·시트 적용)에서
    /// 부른다 — 시트 "초기화"도 결국 `applyFilter`로 들어오므로 여기서 함께 커버된다. best-effort라
    /// 실패해도 무시한다(다음 실행 복원만 놓칠 뿐 현재 세션 동작엔 영향 없음).
    func persistFilter() {
        saveMyLibraryFilterUseCase.execute(state.filter)
    }

    /// 필터 시트 키워드 탭 데이터 로드. 서재 등록 상태에 따라 변하므로 시트를 열 때마다 다시 불러온다.
    func loadRegisteredKeywords() {
        guard keywordsTask == nil else { return }
        keywordsTask = Task { await loadKeywords() }
    }

    /// 목록을 처음부터 다시 로드한다(첫 로드·재시도·필터/정렬 변경 공통).
    /// 진행 중이던 로드는 **취소**해 무효화한다 — 늦게 도착한 이전 결과가 새 목록을 덮지 않는다.
    ///
    /// ⚠️ **취소는 언제나 재대입과 짝이어야 한다** — 취소만 하고 새 Task를 넣지 않으면 슬롯이 non-nil로
    /// 굳어 이후 로드가 전부 막힌다. 불변식 전문은 `loadPage` 주석 참고.
    func reloadFromScratch() {
        loadTask?.cancel()
        nextCursor = nil
        hasNext = true
        state.novels = []
        state.totalCount = 0
        state.isLoading = true
        state.isLoadingMore = false
        state.loadFailed = false
        loadTask = Task { await loadPage(.reload) }
    }
}

// MARK: - UseCase Handling

private extension LibraryViewModel {

    /// 조회 결과를 상태 반영 전 단계로 들고 있는 값. `CursorPaginated`와 전체 수를 한 덩이로 묶어,
    /// **갱신처럼 두 응답을 합쳐야 하는 경우**에도 반영 지점이 하나로 유지되게 한다.
    struct LoadOutcome {
        let items: [LibraryNovel]
        let totalCount: Int
        let nextCursor: String?
        let hasNext: Bool
    }

    /// 서재 로드 본체 — 조회는 `kind`가 정하고, 반영은 취소 확인 뒤 **한 곳에서** 한다.
    /// (시작 표시는 호출자 몫이다: `reloadFromScratch`의 전면 로딩, `loadMore`의 하단 스피너,
    ///  갱신은 아무것도 세우지 않는다.)
    ///
    /// **무효해진 로드 == 취소된 로드**다 — 세대 카운터 없이 `Task.isCancelled`만으로 "늦게 도착한 이전
    /// 결과"를 걸러낼 수 있는 근거는 아래 불변식이다:
    ///
    /// > **로드를 시작하는 모든 경로는 `loadTask == nil`을 확인하거나, 이전 로드를 취소하고 곧바로 재대입한다.**
    ///
    /// `.refresh`는 `reloadFromScratch()`를 거치지 않고 목록을 교체하는 **유일한 예외**인데, 그게 안전한
    /// 이유는 `load()`의 `loadTask == nil` 가드가 "무효화할 이전 로드가 없음"을 보장하기 때문이다 —
    /// **그 가드를 완화하면 세대 카운터가 다시 필요해진다.** 반대로 취소만 하고 재대입하지 않는 경로
    /// (`onDisappear`에서 `cancel()`만 부르는 류)를 만들면 슬롯이 non-nil로 굳어 `load()`가 영구 차단된다.
    ///
    /// `@MainActor`라 가드와 `state` 대입 사이에 suspension이 없어 그 구간이 원자적인 것도 전제다.
    func loadPage(_ kind: LoadKind) async {
        // 시작 전에 이미 취소됐으면 요청조차 내지 않는다 — 낭비도 낭비지만, 그 시점엔
        // `reloadFromScratch()`가 목록을 비운 뒤라 갱신인데도 `size`가 첫 페이지 크기로 찍혀
        // 요청 로그로 2단계를 검증할 때 오진하기 쉽다.
        guard !Task.isCancelled else { return }

        defer {
            // 취소된 로드는 **아무것도 정리하지 않는다** — 정리하면 자기를 밀어낸 새 로드의
            // `loadTask`와 로딩 표시를 지운다. (defer 안에서는 `return`할 수 없어 `if`로 감싼다.)
            if !Task.isCancelled {
                loadTask = nil
                state.isLoading = false
                state.isLoadingMore = false
            }
        }

        do {
            let outcome = try await fetch(kind)
            guard !Task.isCancelled else { return }

            apply(outcome, kind: kind)
            hasLoadedContent = true
            state.loadFailed = false
        } catch {
            guard !Task.isCancelled else { return }
            presentLoadFailure(error, kind: kind)
        }
    }

    /// 네트워크만 수행하고 **상태는 건드리지 않는다** — 반영은 호출자가 취소를 확인한 뒤 한 번에 한다.
    ///
    /// ⚠️ 필터를 **여기서 한 번만 읽어** 아래로 넘긴다 — `state.filter`를 요청 직전마다 다시 읽으면,
    /// 갱신 1·2차 사이에 사용자가 필터를 바꿨을 때 2차가 **새 필터 + 옛 커서**라는 뒤섞인 조합으로 나간다.
    func fetch(_ kind: LoadKind) async throws(RepositoryError) -> LoadOutcome {
        let filter = state.filter

        switch kind {
        case .reload:
            return try await fetchPage(filter: filter, cursor: nil, size: LibraryPageSizePolicy.pageSize)
        case .more(let cursor):
            return try await fetchPage(filter: filter, cursor: cursor, size: LibraryPageSizePolicy.pageSize)
        case .refresh:
            return try await fetchRefreshedList(filter: filter)
        }
    }

    /// 재진입 갱신용 조회 — **보고 있던 개수만큼** 다시 받고, 자리를 비운 사이 늘어난 만큼(delta)을 이어 붙인다.
    ///
    /// 1차만 받아도 **목록 개수는 유지된다**(`size = 보던 개수`라 서버에 그만큼 있으면 그만큼 온다).
    /// 2차가 막는 건 앞에 새 작품이 끼어든 만큼 **이미 지나쳐 본 항목이 window 끝에서 밀려나는 것**이다 —
    /// 스크롤 점프 방지가 아니라 **보던 범위 보존**이고, 없어도 스크롤 한 번이면 복구되는 수준이다.
    /// delta는 "지금 서버의 전체 수"가 있어야 알 수 있고 그건 응답에서만 나오므로 **한 번의 요청으로는
    /// 불가능**하다(대부분의 진입은 delta == 0이라 실제로는 1회 왕복으로 끝난다).
    ///
    /// ⚠️ 두 요청은 **같은 Task 안에서 순차로** 돈다 — 갱신을 별도 Task 슬롯으로 빼면
    /// "무효해진 로드 == 취소된 로드" 전제가 깨져 세대 카운터가 되살아난다(`loadPage` 주석).
    /// 반영도 2차까지 받아 **합쳐서 한 번에** 한다 — 1차를 먼저 반영하면 목록이 한 번 갈렸다 늘어나는 게 보인다.
    func fetchRefreshedList(filter: MyLibraryFilter) async throws(RepositoryError) -> LoadOutcome {
        let previousTotalCount = state.totalCount
        let first = try await fetchPage(
            filter: filter,
            cursor: nil,
            size: LibraryPageSizePolicy.refreshSize(loadedCount: state.novels.count)
        )

        // ⚠️ 1차 응답을 기다리는 동안 취소됐을 수 있다 — 여기서 안 끊으면 **버려질 게 확정된 2차 요청**이
        // 그대로 서버로 나간다(필터 변경으로 취소된 경우가 대표적).
        guard !Task.isCancelled else { return first }

        guard let followUpSize = LibraryPageSizePolicy.followUpSize(
            previousTotalCount: previousTotalCount,
            newTotalCount: first.totalCount,
            hasNext: first.hasNext
        ), let cursor = first.nextCursor else { return first }

        let second = try await fetchPage(filter: filter, cursor: cursor, size: followUpSize)
        return LoadOutcome(
            items: first.items + second.items,
            totalCount: second.totalCount,
            nextCursor: second.nextCursor,
            hasNext: second.hasNext
        )
    }

    func fetchPage(
        filter: MyLibraryFilter,
        cursor: String?,
        size: Int
    ) async throws(RepositoryError) -> LoadOutcome {
        let (page, totalCount) = try await loadMyLibraryUseCase.execute(
            filter: filter,
            cursor: cursor,
            size: size
        )
        return LoadOutcome(
            items: page.items,
            totalCount: totalCount,
            nextCursor: page.nextCursor,
            hasNext: page.hasNext
        )
    }

    /// 조회 결과를 상태에 반영한다. 목록을 세우는 로드(첫 로드·갱신)는 **교체**, 다음 페이지는 **append**.
    func apply(_ outcome: LoadOutcome, kind: LoadKind) {
        switch kind {
        case .reload, .refresh:
            state.novels = outcome.items
        case .more:
            state.novels.append(contentsOf: outcome.items)
        }
        state.totalCount = outcome.totalCount
        nextCursor = outcome.nextCursor
        hasNext = outcome.hasNext
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

    /// 목록 로드 실패는 **첫 페이지·더보기·갱신을 가리지 않고 전면 실패 뷰**로 표현한다.
    ///
    /// 사용자에겐 셋 다 "목록을 못 불러왔다"는 같은 사건이고, 몇 번째 페이지였는지는 앱 내부 사정이다.
    /// 더보기 실패를 토스트로 두면 **복구 수단이 없다** — 토스트는 사라지면 끝이라 다시 부를 방법이
    /// 없고, 실제로 그것 때문에 "하단에서 더보기가 실패하면 그 뒤로 목록이 영영 안 채워지는" 상태가
    /// 만들어졌다(#195 실측). 전면 실패 뷰는 재시도 버튼을 달고 온다.
    /// (홈도 같은 이유로 갱신 실패를 첫 로드와 같게 다룬다 — `HomeFeature/CLAUDE.md`.)
    func presentLoadFailure(_ error: Error, kind: LoadKind) {
        // 인증 만료는 실패 뷰 대신 로그인 유도로 일원화 — 실패 플래그보다 먼저 거른다.
        // (실패 뷰의 재시도가 같은 에러로 되돌아와 탈출구가 되지 못한다.)
        if routeToLoginIfAuthenticationRequired(error) { return }

        // ⚠️ `hasLoadedContent`를 함께 내려야 다음 진입이 '갱신'이 아니라 로딩부터 다시 시작한다.
        hasLoadedContent = false
        state.loadFailed = true
        // ⚠️ `kind`를 그대로 보간하면 `more(cursor: "eyJ...")`로 **서버 커서 원문**이 로그에 통째로 찍힌다.
        logger?.error("Library 목록 로드 실패(\(kind.logLabel)): \(String(describing: error))")
    }

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

        // ⚠️ 세션이 죽었으므로 지금 목록은 **그 계정 기준으로 무효**다 — `hasLoadedContent`를 내려
        // 다음 진입을 첫 로드로 돌린다. 안 내리면 재로그인 뒤 첫 진입이 '갱신'으로 잡혀
        // **이전 계정의 개수**로 size를 정하고 delta를 이전 `totalCount`와 비교한다.
        // 하강을 여기 두는 이유: 목록 로드(`presentLoadFailure`)뿐 아니라 **더보기·키워드 실패**
        // (`presentError`)도 이 함수로 만료를 걸러내므로, 여기가 세 경로를 한 번에 덮는 유일한 지점이다.
        hasLoadedContent = false
        state.requiresAuthentication = true
        return true
    }
}
