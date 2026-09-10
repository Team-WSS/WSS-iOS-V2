//
//  NormalSearchViewModel.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import RecommendationDomain
import SearchDomain
import Logger

@MainActor
@Observable
final class NormalSearchViewModel {

    /// 검색어 최대 길이. 입력 단계(`NormalSearchView`)에서 이 값으로 clamp한다(V1 30자 하드컷 복원, #222).
    static let maxSearchTextCount = 30

    struct State {
        var sosoPickNovels: [SosoPick] = []
        var recentSearchWords: [RecentSearchWord] = []
        var popularKeywords: [Keyword] = []
        var searchText: String = ""
        var autoCompletionWords: [SearchAutoCompletionWord] = []
        var isLoadingAutoCompletion = false
        var isSearchExecuted = false
        var searchResultNovels: [Novel] = []
        var searchResultCount: Int = 0
        var isSearchingResult = false
        var hasSearchResultError: RepositoryError?
        var hasNextSearchResultPage = false
        var isLoadingMoreSearchResults = false
        var isLoading = false
        var hasLoadError = false
    }

    enum Action {
        case loadSosoPick
        case loadRecentSearchWords
        case removeRecentSearchWord(RecentSearchWord)
        case clearRecentSearchWords
        case loadPopularKeywords
        case updateSearchText(String)
        /// 사용자가 직접 실행한 검색(검색바 제출·최근 검색어 칩·자동완성 제안어 탭) — 항상 최근 검색어로 기록한다.
        case executeSearch(String)
        /// 작가 이름 탭 등 "이미 검색된 결과로 진입"하는 경로 전용(#255 QA) — 사용자가 검색을 의도한 게
        /// 아니므로 최근 검색어로 기록하지 않는다. `NormalSearchView.onAppear`만 부른다.
        case executeInitialSearch(String)
        /// 실패한 검색 재시도 — 새 검색이 아니라 방금 실행했던 검색을 그대로 다시 시도하는 것이므로
        /// 그 검색의 기록 여부(`executeSearch`/`executeInitialSearch` 중 어느 쪽이었는지)를 그대로 유지한다.
        case retrySearch
        case loadMoreSearchResults
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var hasLoadedRecentSearchWords = false
    @ObservationIgnored private var recentSearchWordsTask: Task<Void, Never>?
    @ObservationIgnored private var removingRecentSearchWordIDs: Set<SearchWordID> = []
    @ObservationIgnored private var isClearingRecentSearchWords = false
    @ObservationIgnored private var hasLoadedPopularKeywords = false
    @ObservationIgnored private var popularKeywordsTask: Task<Void, Never>?
    @ObservationIgnored private var autoCompletionTask: Task<Void, Never>?
    @ObservationIgnored private var searchResultTask: Task<Void, Never>?
    @ObservationIgnored private var loadMoreSearchResultTask: Task<Void, Never>?
    @ObservationIgnored private var nextSearchResultPage = 0
    /// 지금 보여주고 있는 검색 세션이 최근 검색어로 기록되는 세션인지 — 첫 페이지에서 정해지면 다음
    /// 페이지·재시도 전부 같은 값을 그대로 쓴다(세션 도중 기록 여부가 바뀌면 안 됨).
    @ObservationIgnored private var currentSearchRecordsRecentSearch = true

    // MARK: - Dependency

    // RecommendationDomain
    private let loadSosoPickUseCase: LoadSosoPickUseCase

    // SearchDomain
    private let loadRecentSearchWordsUseCase: LoadRecentSearchWordsUseCase
    private let removeRecentSearchWordUseCase: RemoveRecentSearchWordUseCase
    private let clearRecentSearchWordsUseCase: ClearRecentSearchWordsUseCase
    private let searchAutoCompletionWordsUseCase: SearchAutoCompletionWordsUseCase

    // NovelDomain
    private let searchNovelUseCase: SearchNovelUseCase

    // BaseDomain
    private let loadPopularKeywordsUseCase: LoadPopularKeywordsUseCase

    private let logger: Logger?

    // MARK: - Init

    init(
        loadSosoPickUseCase: LoadSosoPickUseCase,
        loadRecentSearchWordsUseCase: LoadRecentSearchWordsUseCase,
        removeRecentSearchWordUseCase: RemoveRecentSearchWordUseCase,
        clearRecentSearchWordsUseCase: ClearRecentSearchWordsUseCase,
        searchAutoCompletionWordsUseCase: SearchAutoCompletionWordsUseCase,
        searchNovelUseCase: SearchNovelUseCase,
        loadPopularKeywordsUseCase: LoadPopularKeywordsUseCase,
        logger: Logger? = nil,
        initialQuery: String? = nil
    ) {
        self.loadSosoPickUseCase = loadSosoPickUseCase
        self.loadRecentSearchWordsUseCase = loadRecentSearchWordsUseCase
        self.removeRecentSearchWordUseCase = removeRecentSearchWordUseCase
        self.clearRecentSearchWordsUseCase = clearRecentSearchWordsUseCase
        self.searchAutoCompletionWordsUseCase = searchAutoCompletionWordsUseCase
        self.searchNovelUseCase = searchNovelUseCase
        self.loadPopularKeywordsUseCase = loadPopularKeywordsUseCase
        self.logger = logger

        // 작가 이름 탭(`NovelDetailFeature`) 등 "이미 검색된 결과로 진입"하는 경로용 — 검색어만 미리
        // 채워둔다. ⚠️ **실제 검색 실행(Task 스폰)은 여기서 하지 않는다(#255 QA 실측 버그 수정)** —
        // 이 인스턴스는 `NormalSearchView.init`의 `State(initialValue:)` 인자 표현식으로 만들어지는데,
        // 그 표현식은 "값이 저장에 반영되는 건 최초 1회"와 무관하게 **`.navigationDestination(for:)`가
        // 재평가될 때마다(App Root의 다른 `@State`가 바뀌기만 해도) 매번 다시 실행된다** — 그때마다
        // 새로 만들어졌다 버려지는 "고아" 인스턴스가 여기서 `executeSearch`로 Task를 스폰해버리면 그
        // 고아도 실제 네트워크 요청(`/novels` 검색 + 성공 시 `/novels/recent-searches` 재조회)을
        // 끝까지 완주한다 — 화면을 가만히 둬도 두 API가 계속 반복 호출되는 버그로 실측됐다. 실제 검색
        // 실행은 `NormalSearchView`가 `onAppear`에서 1회 가드(`didRunInitialSearch`)로 호출한다 —
        // `onAppear`는 실제로 화면에 붙는 단 하나의 인스턴스에서만 발화하므로 고아는 이 경로를 안 탄다.
        if let initialQuery, !initialQuery.isEmpty {
            state.searchText = initialQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .loadSosoPick:
            loadSosoPick()
        case .loadRecentSearchWords:
            loadRecentSearchWords()
        case .removeRecentSearchWord(let word):
            removeRecentSearchWord(word)
        case .clearRecentSearchWords:
            clearRecentSearchWords()
        case .loadPopularKeywords:
            loadPopularKeywords()
        case .updateSearchText(let text):
            updateSearchText(text)
        case .executeSearch(let text):
            executeSearch(text)
        case .executeInitialSearch(let text):
            executeInitialSearch(text)
        case .retrySearch:
            retrySearch()
        case .loadMoreSearchResults:
            loadMoreSearchResults()
        }
    }

}

// MARK: - Action Handling

private extension NormalSearchViewModel {
    func loadSosoPick() {
        guard !hasLoaded, loadTask == nil else { return }
        state.isLoading = true
        state.hasLoadError = false
        loadTask = Task { await loadSosoPickNovels() }
    }

    func loadRecentSearchWords() {
        guard !hasLoadedRecentSearchWords, recentSearchWordsTask == nil else { return }
        recentSearchWordsTask = Task { await loadRecentSearchWordsList() }
    }

    /// 검색 실행 성공 시 서버가 최근 검색어를 자동 기록하므로, 방금 실행한 검색어가 목록에 즉시 반영되도록
    /// `hasLoadedRecentSearchWords` 가드를 우회해 다시 불러온다. **기록 대상 검색(`recordRecentSearch: true`)의
    /// 성공 시에만** `loadSearchResult`가 이 함수를 호출한다 — 기록 안 하는 검색(작가 이름 탭 등)까지 부르면
    /// 아무것도 안 바뀐 목록을 의미 없이 다시 받아온다.
    func refreshRecentSearchWordsAfterSearch() {
        recentSearchWordsTask?.cancel()
        recentSearchWordsTask = Task { await loadRecentSearchWordsList() }
    }

    /// UI에 낙관적으로 먼저 반영한 뒤 서버 동기화 실패 시 그 단어만 되돌린다.
    /// 전체 삭제와는 상호 배타적(동시 진행 시 배열 스냅샷 롤백이 서로를 덮어써 데이터 불일치가 남는다).
    func removeRecentSearchWord(_ word: RecentSearchWord) {
        guard !isClearingRecentSearchWords, !removingRecentSearchWordIDs.contains(word.id) else { return }
        state.recentSearchWords.removeAll { $0.id == word.id }
        removingRecentSearchWordIDs.insert(word.id)
        Task { await syncRemoveRecentSearchWord(word) }
    }

    /// UI에 낙관적으로 먼저 반영한 뒤 서버 동기화 실패 시 롤백한다.
    /// 개별 삭제와 상호 배타적 — 진행 중인 개별 삭제가 있으면 그 스냅샷 복원과 충돌할 수 있어 대기시킨다.
    func clearRecentSearchWords() {
        guard !isClearingRecentSearchWords, removingRecentSearchWordIDs.isEmpty, !state.recentSearchWords.isEmpty else { return }
        let before = state.recentSearchWords
        state.recentSearchWords = []
        isClearingRecentSearchWords = true
        Task { await syncClearRecentSearchWords(rollbackTo: before) }
    }

    func loadPopularKeywords() {
        guard !hasLoadedPopularKeywords, popularKeywordsTask == nil else { return }
        popularKeywordsTask = Task { await loadPopularKeywordsList() }
    }

    /// 입력마다 이전 요청은 취소하고 새로 debounce한다(타이핑 중 매 글자마다 서버를 치지 않기 위함).
    /// 검색 실행 후 다시 타이핑하면 결과 화면을 벗어나 자동완성으로 돌아간다(`isSearchExecuted` 해제).
    /// 텍스트가 실제로 안 바뀌면 무시 — `WSSSearchBar`가 키보드를 내릴 때(검색 실행 직후 포함) 같은 값으로
    /// 바인딩을 한 번 더 커밋해, 가드가 없으면 방금 실행한 검색(`isSearchExecuted`)이 곧바로 취소돼버린다.
    func updateSearchText(_ text: String) {
        guard text != state.searchText else { return }
        state.searchText = text
        state.isSearchExecuted = false
        autoCompletionTask?.cancel()

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.autoCompletionWords = []
            state.isLoadingAutoCompletion = false
            return
        }
        state.isLoadingAutoCompletion = true
        autoCompletionTask = Task { await loadAutoCompletionWords(searchText: text) }
    }

    /// 검색바 onSearch, 최근 검색어·키워드 칩, 자동완성 제안어 선택에서 공통으로 호출하는 검색 실행 지점 —
    /// 사용자가 직접 검색을 의도한 경우라 최근 검색어로 기록한다.
    func executeSearch(_ text: String) {
        performSearch(text, recordRecentSearch: true)
    }

    /// 작가 이름 탭 등 "이미 검색된 결과로 진입"하는 경로 전용(#255 QA) — 사용자가 검색을 의도한 게
    /// 아니므로 기록하지 않는다.
    func executeInitialSearch(_ text: String) {
        performSearch(text, recordRecentSearch: false)
    }

    /// 실패한 검색의 재시도 — 새 검색이 아니라 방금 검색을 그대로 다시 시도하는 것이라, 그 검색이
    /// 기록 대상이었는지 여부(`currentSearchRecordsRecentSearch`)를 그대로 유지한다.
    func retrySearch() {
        performSearch(state.searchText, recordRecentSearch: currentSearchRecordsRecentSearch)
    }

    /// 자동완성 debounce와 경합하지 않도록 그 Task를 취소하고 결과 조회로 전환한다.
    func performSearch(_ text: String, recordRecentSearch: Bool) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        currentSearchRecordsRecentSearch = recordRecentSearch
        state.searchText = trimmedText
        autoCompletionTask?.cancel()
        state.autoCompletionWords = []
        state.isLoadingAutoCompletion = false
        state.isSearchExecuted = true

        searchResultTask?.cancel()
        loadMoreSearchResultTask?.cancel()
        loadMoreSearchResultTask = nil
        state.isSearchingResult = true
        state.hasSearchResultError = nil
        state.hasNextSearchResultPage = false
        searchResultTask = Task { await loadSearchResult(searchText: trimmedText, recordRecentSearch: recordRecentSearch) }
    }

    /// 검색 결과 리스트 마지막 행이 보일 때 View가 호출(무한스크롤). 다음 페이지가 없거나 이미 로딩 중이면 무시.
    func loadMoreSearchResults() {
        guard state.isSearchExecuted,
              state.hasNextSearchResultPage,
              searchResultTask == nil,
              loadMoreSearchResultTask == nil else { return }
        state.isLoadingMoreSearchResults = true
        loadMoreSearchResultTask = Task {
            await loadMoreSearchResultPage(searchText: state.searchText, recordRecentSearch: currentSearchRecordsRecentSearch)
        }
    }
}

// MARK: - UseCase Handling

private extension NormalSearchViewModel {
    func loadSosoPickNovels() async {
        defer {
            loadTask = nil
            state.isLoading = false
        }

        do {
            let picks = try await loadSosoPickUseCase.execute()
            guard !Task.isCancelled else { return }
            state.sosoPickNovels = picks
            hasLoaded = true
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("SosoPick 실패(loadSosoPick): \(String(describing: error))")
            state.hasLoadError = true
        }
    }

    func loadRecentSearchWordsList() async {
        defer { recentSearchWordsTask = nil }

        do {
            let words = try await loadRecentSearchWordsUseCase.execute()
            guard !Task.isCancelled else { return }
            state.recentSearchWords = words
            hasLoadedRecentSearchWords = true
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("최근 검색어 조회 실패: \(String(describing: error))")
        }
    }

    func syncRemoveRecentSearchWord(_ word: RecentSearchWord) async {
        defer { removingRecentSearchWordIDs.remove(word.id) }

        do {
            try await removeRecentSearchWordUseCase.execute(word: word)
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("최근 검색어 삭제 실패: \(String(describing: error))")
            if !state.recentSearchWords.contains(where: { $0.id == word.id }) {
                state.recentSearchWords.append(word)
            }
        }
    }

    func syncClearRecentSearchWords(rollbackTo before: [RecentSearchWord]) async {
        defer { isClearingRecentSearchWords = false }

        do {
            try await clearRecentSearchWordsUseCase.execute()
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("최근 검색어 전체 삭제 실패: \(String(describing: error))")
            state.recentSearchWords = before
        }
    }

    func loadPopularKeywordsList() async {
        defer { popularKeywordsTask = nil }

        do {
            let popularKeywords = try await loadPopularKeywordsUseCase.execute()
            guard !Task.isCancelled else { return }
            state.popularKeywords = popularKeywords.keywords
            hasLoadedPopularKeywords = true
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("인기 키워드 조회 실패: \(String(describing: error))")
        }
    }

    func loadAutoCompletionWords(searchText: String) async {
        // 짧은 debounce — 타이핑이 끝난 뒤에만 조회한다.
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled else { return }

        defer {
            autoCompletionTask = nil
            state.isLoadingAutoCompletion = false
        }

        do {
            let words = try await searchAutoCompletionWordsUseCase.execute(searchText: searchText)
            guard !Task.isCancelled else { return }
            state.autoCompletionWords = words
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("검색어 자동완성 조회 실패: \(String(describing: error))")
            state.autoCompletionWords = []
        }
    }

    func loadSearchResult(searchText: String, recordRecentSearch: Bool) async {
        defer {
            searchResultTask = nil
            state.isSearchingResult = false
        }

        do {
            let (paginated, resultCount) = try await searchNovelUseCase.searchByText(searchText, page: 0, recordRecentSearch: recordRecentSearch)
            guard !Task.isCancelled else { return }
            state.searchResultNovels = paginated.items
            state.searchResultCount = resultCount
            state.hasNextSearchResultPage = paginated.hasNext
            nextSearchResultPage = 1
            // 기록 대상이 아니었던 검색(작가 이름 탭 등)은 서버가 아무것도 새로 안 남겨 다시 불러와도
            // 목록이 그대로다 — 불필요한 `/novels/recent-searches` 호출을 만들지 않는다.
            if recordRecentSearch {
                refreshRecentSearchWordsAfterSearch()
            }
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("작품 검색 실패: \(String(describing: error))")
            state.hasSearchResultError = (error as? RepositoryError) ?? .unknown
        }
    }

    func loadMoreSearchResultPage(searchText: String, recordRecentSearch: Bool) async {
        defer {
            loadMoreSearchResultTask = nil
            state.isLoadingMoreSearchResults = false
        }

        do {
            let (paginated, resultCount) = try await searchNovelUseCase.searchByText(searchText, page: nextSearchResultPage, recordRecentSearch: recordRecentSearch)
            guard !Task.isCancelled else { return }
            state.searchResultNovels.append(contentsOf: paginated.items)
            state.searchResultCount = resultCount
            state.hasNextSearchResultPage = paginated.hasNext
            nextSearchResultPage += 1
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("작품 검색 다음 페이지 실패: \(String(describing: error))")
        }
    }
}
