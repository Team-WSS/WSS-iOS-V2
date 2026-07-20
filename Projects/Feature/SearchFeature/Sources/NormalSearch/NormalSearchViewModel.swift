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

    // MARK: - Dependency

    // RecommendationDomain
    private let loadSosoPickUseCase: LoadSosoPickUseCase

    // SearchDomain
    private let loadRecentSearchWordsUseCase: LoadRecentSearchWordsUseCase
    private let removeRecentSearchWordUseCase: RemoveRecentSearchWordUseCase
    private let clearRecentSearchWordsUseCase: ClearRecentSearchWordsUseCase
    private let searchAutoCompletionWordsUseCase: SearchAutoCompletionWordsUseCase

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
        loadPopularKeywordsUseCase: LoadPopularKeywordsUseCase,
        logger: Logger? = nil
    ) {
        self.loadSosoPickUseCase = loadSosoPickUseCase
        self.loadRecentSearchWordsUseCase = loadRecentSearchWordsUseCase
        self.removeRecentSearchWordUseCase = removeRecentSearchWordUseCase
        self.clearRecentSearchWordsUseCase = clearRecentSearchWordsUseCase
        self.searchAutoCompletionWordsUseCase = searchAutoCompletionWordsUseCase
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
    func updateSearchText(_ text: String) {
        state.searchText = text
        autoCompletionTask?.cancel()

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.autoCompletionWords = []
            return
        }
        autoCompletionTask = Task { await loadAutoCompletionWords(searchText: text) }
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
}
