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
public class NormalSearchViewModel {

    struct State {
        var sosoPickNovels: [SosoPick] = []
        var recentSearchWords: [RecentSearchWord] = []
        var isLoading = false
        var hasLoadError = false
    }

    enum Action {
        case loadSosoPick
        case loadRecentSearchWords
        case removeRecentSearchWord(RecentSearchWord)
        case clearRecentSearchWords
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

    // MARK: - Dependency

    // RecommendationDomain
    private let loadSosoPickUseCase: LoadSosoPickUseCase

    // SearchDomain
    private let loadRecentSearchWordsUseCase: LoadRecentSearchWordsUseCase
    private let removeRecentSearchWordUseCase: RemoveRecentSearchWordUseCase
    private let clearRecentSearchWordsUseCase: ClearRecentSearchWordsUseCase

    private let logger: Logger?

    // MARK: - Init

    init(
        loadSosoPickUseCase: LoadSosoPickUseCase,
        loadRecentSearchWordsUseCase: LoadRecentSearchWordsUseCase,
        removeRecentSearchWordUseCase: RemoveRecentSearchWordUseCase,
        clearRecentSearchWordsUseCase: ClearRecentSearchWordsUseCase,
        logger: Logger? = nil
    ) {
        self.loadSosoPickUseCase = loadSosoPickUseCase
        self.loadRecentSearchWordsUseCase = loadRecentSearchWordsUseCase
        self.removeRecentSearchWordUseCase = removeRecentSearchWordUseCase
        self.clearRecentSearchWordsUseCase = clearRecentSearchWordsUseCase
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

    /// UI에 낙관적으로 먼저 반영한 뒤 서버 동기화 실패 시 롤백한다.
    func removeRecentSearchWord(_ word: RecentSearchWord) {
        guard !removingRecentSearchWordIDs.contains(word.id) else { return }
        let before = state.recentSearchWords
        state.recentSearchWords.removeAll { $0.id == word.id }
        removingRecentSearchWordIDs.insert(word.id)
        Task { await syncRemoveRecentSearchWord(word, rollbackTo: before) }
    }

    /// UI에 낙관적으로 먼저 반영한 뒤 서버 동기화 실패 시 롤백한다(개별 삭제와 같은 패턴).
    func clearRecentSearchWords() {
        guard !isClearingRecentSearchWords, !state.recentSearchWords.isEmpty else { return }
        let before = state.recentSearchWords
        state.recentSearchWords = []
        isClearingRecentSearchWords = true
        Task { await syncClearRecentSearchWords(rollbackTo: before) }
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

    func syncRemoveRecentSearchWord(_ word: RecentSearchWord, rollbackTo before: [RecentSearchWord]) async {
        defer { removingRecentSearchWordIDs.remove(word.id) }

        do {
            try await removeRecentSearchWordUseCase.execute(word: word)
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("최근 검색어 삭제 실패: \(String(describing: error))")
            state.recentSearchWords = before
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
}
