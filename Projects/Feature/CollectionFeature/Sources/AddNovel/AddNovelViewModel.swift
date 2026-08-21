//
//  AddNovelViewModel.swift
//  CollectionFeature
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import CollectionDomain
import SearchDomain
import Logger

/// 컬렉션 "작품 추가" 화면 — 검색해서 다중선택한 결과를 `CreateCollectionView`로 되돌려준다.
/// `ReadingPeriodSheet`처럼 이 모듈 내부에서만 push되는 로컬 화면이라 Factory로 노출하지 않는다
/// (`CollectionFeature/CLAUDE.md` 참고).
@MainActor
@Observable
final class AddNovelViewModel {

    // MARK: - State

    struct State {
        var searchText: String = ""
        var searchedNovels: [Novel] = []
        /// 검색 결과와 별개로 유지 — 검색어를 바꿔도 이미 고른 작품은 그대로 남아야 한다
        /// (`KeywordFeature.selectedKeywords`와 같은 구조). 순서 = 선택 순서.
        var selectedNovels: [CollectionNovel]
        var isSearching = false
        /// 현재 `searchText`로 검색이 **실제로 완료**됐는지. 타이핑은 `updateSearchText`에서 매 글자마다
        /// 이 값을 꺼뜨려, 검색 실행 전(또는 결과를 받은 뒤 다시 타이핑하는 도중)엔 결과 없음 뷰가 아니라
        /// 빈 화면이 보이게 한다 — `search()`가 실제로 응답을 받아야만 다시 켜진다.
        var hasSearched = false
        var isConfirmed = false
        var requiresAuthentication = false
        var presentedError: SearchError?
    }

    enum SearchError: Equatable {
        case unknown
    }

    // MARK: - Derived

    var selectedNovelIDs: Set<NovelID> { Set(state.selectedNovels.map(\.id)) }
    var isAtCapacity: Bool { state.selectedNovels.count >= CollectionDraft.maxNovelCount }

    // MARK: - Action

    enum Action {
        case updateSearchText(String)
        case search(String)
        case toggleNovel(Novel)
        case confirm
        case dismissError
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    @ObservationIgnored private var searchTask: Task<Void, Never>?

    // MARK: - Dependency

    private let logger: Logger?

    // SearchDomain
    private let searchNovelUseCase: SearchNovelUseCase

    // MARK: - Init

    init(
        initialSelection: [CollectionNovel],
        searchNovelUseCase: SearchNovelUseCase,
        logger: Logger? = nil
    ) {
        self.searchNovelUseCase = searchNovelUseCase
        self.logger = logger
        self.state = State(selectedNovels: initialSelection)
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .updateSearchText(let text):
            state.searchText = text
            state.hasSearched = false
        case .search(let query):
            search(query)
        case .toggleNovel(let novel):
            toggleNovel(novel)
        case .confirm:
            state.isConfirmed = true
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension AddNovelViewModel {

    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask?.cancel()
        guard !trimmed.isEmpty else {
            state.searchedNovels = []
            return
        }
        searchTask = Task { await searchNovels(trimmed) }
    }

    /// 선택 토글. 이미 골랐으면 해제, 아니면 담는다 — 정원(100개)이 차면 더 담지 않는다(초과 시도 시
    /// 별도 피드백은 아직 없음 — 3B 미결, 디자인 확인 후 필요하면 토스트 추가).
    func toggleNovel(_ novel: Novel) {
        if let index = state.selectedNovels.firstIndex(where: { $0.id == novel.id }) {
            state.selectedNovels.remove(at: index)
        } else {
            guard !isAtCapacity else { return }
            state.selectedNovels.append(
                CollectionNovel(
                    id: novel.id,
                    title: novel.title,
                    author: novel.authors.first ?? "",
                    thumbnailImage: novel.thumbnailImage
                )
            )
        }
    }
}

// MARK: - UseCase Handling

private extension AddNovelViewModel {

    func searchNovels(_ query: String) async {
        state.isSearching = true
        defer { state.isSearching = false }

        do {
            let (paginated, _) = try await searchNovelUseCase.searchByText(query, page: 0)
            guard !Task.isCancelled else { return }
            state.searchedNovels = paginated.items
            state.hasSearched = true
        } catch {
            guard !Task.isCancelled else { return }
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension AddNovelViewModel {

    func presentError(_ error: Error) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("AddNovel 검색 실패: \(String(describing: error))")
        state.presentedError = .unknown
    }

    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
