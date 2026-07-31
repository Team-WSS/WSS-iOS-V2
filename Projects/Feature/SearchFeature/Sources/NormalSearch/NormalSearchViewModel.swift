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

    struct State {
        var sosoPickNovels: [SosoPick] = []
        var recentSearchWords: [RecentSearchWord] = []
        var popularKeywords: [Keyword] = []
        var searchText: String = ""
        var autoCompletionWords: [SearchAutoCompletionWord] = []
        var isSearchExecuted = false
        var searchResultNovels: [Novel] = []
        var searchResultCount: Int = 0
        var isSearchingResult = false
        var hasSearchResultError = false
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
        case executeSearch(String)
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
        logger: Logger? = nil
    ) {
        self.loadSosoPickUseCase = loadSosoPickUseCase
        self.loadRecentSearchWordsUseCase = loadRecentSearchWordsUseCase
        self.removeRecentSearchWordUseCase = removeRecentSearchWordUseCase
        self.clearRecentSearchWordsUseCase = clearRecentSearchWordsUseCase
        self.searchAutoCompletionWordsUseCase = searchAutoCompletionWordsUseCase
        self.searchNovelUseCase = searchNovelUseCase
        self.loadPopularKeywordsUseCase = loadPopularKeywordsUseCase
        self.logger = logger
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
        case .loadMoreSearchResults:
            loadMoreSearchResults()
        }
    }

    // MARK: - Navigation

    /// 장르 탭·키워드 탭이 누르는 순간 `DetailSearchResultView`로 전환하기 위한 자식 화면 조립.
    /// App 라우터가 아직 없어(#165 시점 스켈레톤) 같은 모듈 안의 `NormalSearchView`가 직접 push하는데,
    /// View는 UseCase를 직접 들지 않는 규칙(View→VM만)을 지키려고 이미 보유한 `searchNovelUseCase`로 여기서 조립해 건네준다.
    func makeDetailSearchResultViewModel(filter: SearchFilter) -> DetailSearchResultViewModel {
        DetailSearchResultViewModel(filter: filter, searchNovelUseCase: searchNovelUseCase, logger: logger)
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

    /// 검색 실행 성공 시 서버가 최근 검색어를 자동 기록하므로, 방금 실행한 검색어가 목록에 즉시 반영되도록 무조건 다시 불러온다(`hasLoadedRecentSearchWords` 가드 우회).
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
            return
        }
        autoCompletionTask = Task { await loadAutoCompletionWords(searchText: text) }
    }

    /// 검색바 onSearch, 최근 검색어·키워드 칩, 자동완성 제안어 선택에서 공통으로 호출하는 검색 실행 지점.
    /// 자동완성 debounce와 경합하지 않도록 그 Task를 취소하고 결과 조회로 전환한다.
    func executeSearch(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        state.searchText = trimmedText
        autoCompletionTask?.cancel()
        state.autoCompletionWords = []
        state.isSearchExecuted = true

        searchResultTask?.cancel()
        loadMoreSearchResultTask?.cancel()
        loadMoreSearchResultTask = nil
        state.isSearchingResult = true
        state.hasSearchResultError = false
        state.hasNextSearchResultPage = false
        searchResultTask = Task { await loadSearchResult(searchText: trimmedText) }
    }

    /// 검색 결과 리스트 마지막 행이 보일 때 View가 호출(무한스크롤). 다음 페이지가 없거나 이미 로딩 중이면 무시.
    func loadMoreSearchResults() {
        guard state.isSearchExecuted,
              state.hasNextSearchResultPage,
              searchResultTask == nil,
              loadMoreSearchResultTask == nil else { return }
        state.isLoadingMoreSearchResults = true
        loadMoreSearchResultTask = Task { await loadMoreSearchResultPage(searchText: state.searchText) }
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

        defer { autoCompletionTask = nil }

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

    func loadSearchResult(searchText: String) async {
        defer {
            searchResultTask = nil
            state.isSearchingResult = false
        }

        do {
            let (paginated, resultCount) = try await searchNovelUseCase.searchByText(searchText, page: 0)
            guard !Task.isCancelled else { return }
            state.searchResultNovels = paginated.items
            state.searchResultCount = resultCount
            state.hasNextSearchResultPage = paginated.hasNext
            nextSearchResultPage = 1
            refreshRecentSearchWordsAfterSearch()
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("작품 검색 실패: \(String(describing: error))")
            state.hasSearchResultError = true
        }
    }

    func loadMoreSearchResultPage(searchText: String) async {
        defer {
            loadMoreSearchResultTask = nil
            state.isLoadingMoreSearchResults = false
        }

        do {
            let (paginated, resultCount) = try await searchNovelUseCase.searchByText(searchText, page: nextSearchResultPage)
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
