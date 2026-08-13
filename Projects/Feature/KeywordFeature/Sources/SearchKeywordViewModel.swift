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

    enum PresentedError: Equatable {
        case unknown
        case selectionOverLimit(max: Int)
    }

    /// 선택 가능한 최대 개수 — `SearchDomain.SearchFilter`의 키워드 20개 제한과 맞춘 고정값(#185).
    /// 이 화면은 그 도메인을 모르므로 여기 독립적으로 고정해두되, 저쪽 제한이 바뀌면 같이 맞춰야 한다.
    static let maxSelectionCount = 20

    // MARK: - Action

    enum Action {
        case load
        case search(text: String)
        case toggleKeyword(Keyword)
        case resetSelectedKeywords
        case dismissError
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Dependency

    private let logger: Logger?

    // BaseDomain (Keyword)
    private let loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase
    private let searchKeywordsUseCase: SearchKeywordsUseCase

    // MARK: - Init

    /// `initialSelectedKeywords` — 다른 화면에서 이미 선택된 키워드를 들고 진입할 때 시딩한다
    /// (#185, `SearchFeature`의 상세탐색 필터 "키워드" 탭 재진입 등). 기본은 빈 선택.
    init(
        loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase,
        searchKeywordsUseCase: SearchKeywordsUseCase,
        initialSelectedKeywords: [Keyword] = [],
        logger: Logger? = nil
    ) {
        self.loadTotalKeywordsUseCase = loadTotalKeywordsUseCase
        self.searchKeywordsUseCase = searchKeywordsUseCase
        self.logger = logger
        self.state = State(selectedKeywords: initialSelectedKeywords)
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

    /// 이미 선택된 키워드면 해제, 아니면 선택 트레이 맨 뒤에 추가한다. 이미 최대 개수를 채운 상태에서
    /// 새 키워드를 추가하려 하면 선택하지 않고 토스트로 안내한다.
    func toggleKeyword(_ keyword: Keyword) {
        if let index = state.selectedKeywords.firstIndex(of: keyword) {
            state.selectedKeywords.remove(at: index)
        } else if state.selectedKeywords.count >= Self.maxSelectionCount {
            state.presentedError = .selectionOverLimit(max: Self.maxSelectionCount)
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
