//
//  SearchKeywordViewModel.swift
//  KeywordFeature
//
//  Created by Seoyeon Choi on 7/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import Logger

@MainActor
@Observable
final class SearchKeywordViewModel {

    // MARK: - State

    struct State {
        var groups: [KeywordGroup] = []
        /// 마지막으로 요청한 검색어. 응답이 늦게 와도 그사이 검색어가 바뀌었으면 버리기 위한 기준값(stale 가드).
        var query: String = ""
        var searchedKeywords: [Keyword] = []
        /// 선택 순서를 유지한다(선택 트레이에 선택한 순서대로 표시).
        var selectedKeywords: [Keyword] = []
        var presentedError: PresentedError?
    }

    enum PresentedError: Equatable { case unknown }

    // MARK: - Action

    enum Action {
        case load
        case search(text: String)
        case toggleKeyword(Keyword)
        case resetSelectedKeywords
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Dependency

    private let logger: Logger?

    // BaseDomain (Keyword)
    private let loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase
    private let searchKeywordsUseCase: SearchKeywordsUseCase

    // MARK: - Init

    init(
        loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase,
        searchKeywordsUseCase: SearchKeywordsUseCase,
        logger: Logger? = nil
    ) {
        self.loadTotalKeywordsUseCase = loadTotalKeywordsUseCase
        self.searchKeywordsUseCase = searchKeywordsUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .search(let text):
            search(text: text)
        case .toggleKeyword(let keyword):
            toggleKeyword(keyword)
        case .resetSelectedKeywords:
            state.selectedKeywords.removeAll()
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension SearchKeywordViewModel {
    func load() {
        Task { await loadKeywordGroups() }
    }

    /// 검색어가 비면 목록만 비우고(브라우징 화면으로 복귀) 서버/캐시 호출은 하지 않는다.
    func search(text: String) {
        state.query = text
        guard !text.isEmpty else {
            state.searchedKeywords = []
            return
        }
        Task { await searchKeywords(query: text) }
    }

    /// 이미 선택된 키워드면 해제, 아니면 선택 트레이 맨 뒤에 추가한다.
    func toggleKeyword(_ keyword: Keyword) {
        if let index = state.selectedKeywords.firstIndex(of: keyword) {
            state.selectedKeywords.remove(at: index)
        } else {
            state.selectedKeywords.append(keyword)
        }
    }
}

// MARK: - UseCase Handling

private extension SearchKeywordViewModel {
    func loadKeywordGroups() async {
        do {
            state.groups = try await loadTotalKeywordsUseCase.execute()
        } catch {
            presentError(error)
        }
    }

    func searchKeywords(query: String) async {
        do {
            let result = try await searchKeywordsUseCase.execute(searchText: query)
            guard state.query == query else { return } // 응답 도착 시점에 검색어가 이미 바뀌었으면 버린다.
            state.searchedKeywords = result
        } catch {
            guard state.query == query else { return }
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension SearchKeywordViewModel {
    func presentError(_ error: Error) {
        logger?.error("SearchKeyword 키워드 로드 실패: \(String(describing: error))")
        state.presentedError = .unknown
    }
}
