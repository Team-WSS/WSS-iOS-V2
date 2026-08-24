//
//  CollectionSearchNovelViewModel.swift
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
final class CollectionSearchNovelViewModel {

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
        /// 무한스크롤 — `SearchFeature.NormalSearchViewModel`과 동일한 정수 `page`(0부터) 방식.
        var hasNextSearchPage = false
        var isLoadingMore = false
        var isConfirmed = false
        var requiresAuthentication = false
        var presentedError: SearchError?
    }

    enum SearchError: Equatable {
        case unknown
        /// 정원(100개) 도달 후 더 담으려 할 때. 토스트 문구는 `WSSToastType.selectionOverLimit`의
        /// 범용 문구를 임시로 쓴다 — 기획팀 확정 문구 전달 예정(2026-08-24).
        case selectionLimitReached
    }

    // MARK: - Derived

    var selectedNovelIDs: Set<NovelID> { Set(state.selectedNovels.map(\.id)) }
    var isAtCapacity: Bool { state.selectedNovels.count >= CollectionDraft.maxNovelCount }

    // MARK: - Action

    enum Action {
        case updateSearchText(String)
        case search(String)
        case loadMore
        case toggleNovel(Novel)
        case confirm
        case dismissError
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var loadMoreTask: Task<Void, Never>?
    /// 다음에 요청할 페이지 번호 — 첫 검색 성공 시 1로, 다음 페이지 성공마다 +1(`SearchFeature`와 동일 관례).
    @ObservationIgnored private var nextSearchPage = 0

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
        case .loadMore:
            loadMore()
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

private extension CollectionSearchNovelViewModel {

    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask?.cancel()
        loadMoreTask?.cancel()
        loadMoreTask = nil
        state.isLoadingMore = false
        state.hasNextSearchPage = false
        guard !trimmed.isEmpty else {
            state.searchedNovels = []
            return
        }
        searchTask = Task { await searchNovels(trimmed) }
    }

    /// 검색 결과 리스트 마지막 행이 보일 때 View가 호출(무한스크롤). 다음 페이지가 없거나 이미
    /// 검색/로딩 중이면 무시(`SearchFeature.NormalSearchViewModel.loadMoreSearchResults`와 동일 가드).
    func loadMore() {
        guard state.hasSearched,
              state.hasNextSearchPage,
              searchTask == nil,
              loadMoreTask == nil else { return }
        state.isLoadingMore = true
        let query = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        loadMoreTask = Task { await loadMoreNovels(query) }
    }

    /// 선택 토글. 이미 골랐으면 해제, 아니면 담는다 — 정원(100개)이 차면 더 담지 않고 토스트로 알린다.
    func toggleNovel(_ novel: Novel) {
        if let index = state.selectedNovels.firstIndex(where: { $0.id == novel.id }) {
            state.selectedNovels.remove(at: index)
        } else {
            guard !isAtCapacity else {
                state.presentedError = .selectionLimitReached
                return
            }
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

private extension CollectionSearchNovelViewModel {

    func searchNovels(_ query: String) async {
        state.isSearching = true
        // ⚠️ `searchTask`를 여기서 반드시 nil로 되돌려야 한다 — 안 그러면 완료된 뒤에도 계속 값을 들고
        // 있어 `loadMore()`의 `searchTask == nil` 가드가 영원히 막힌다(무한스크롤이 첫 검색 이후 죽는
        // 실제 버그였다).
        defer {
            searchTask = nil
            state.isSearching = false
        }

        do {
            let (paginated, _) = try await searchNovelUseCase.searchByText(query, page: 0)
            guard !Task.isCancelled else { return }
            state.searchedNovels = paginated.items
            state.hasSearched = true
            state.hasNextSearchPage = paginated.hasNext
            nextSearchPage = 1
        } catch {
            guard !Task.isCancelled else { return }
            presentError(error)
        }
    }

    func loadMoreNovels(_ query: String) async {
        defer {
            loadMoreTask = nil
            state.isLoadingMore = false
        }

        do {
            let (paginated, _) = try await searchNovelUseCase.searchByText(query, page: nextSearchPage)
            guard !Task.isCancelled else { return }
            state.searchedNovels.append(contentsOf: paginated.items)
            state.hasNextSearchPage = paginated.hasNext
            nextSearchPage += 1
        } catch {
            guard !Task.isCancelled else { return }
            // 다음 페이지 실패는 토스트로 전체 검색을 방해하지 않는다(이미 보이는 결과는 그대로 유지) —
            // `SearchFeature.NormalSearchViewModel.loadMoreSearchResultPage`와 동일하게 로깅만 한다.
            logger?.error("CollectionSearchNovel 다음 페이지 검색 실패: \(String(describing: error))")
        }
    }
}

// MARK: - Error Mapping

private extension CollectionSearchNovelViewModel {

    func presentError(_ error: Error) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("CollectionSearchNovel 검색 실패: \(String(describing: error))")
        state.presentedError = .unknown
    }

    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
