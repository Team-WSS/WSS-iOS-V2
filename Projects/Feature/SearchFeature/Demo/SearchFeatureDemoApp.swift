//
//  SearchFeatureDemoApp.swift
//  SearchFeatureDemo
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import SearchFeature
import BaseDomain
import RecommendationDomain
import SearchDomain
import BaseData
import RecommendationData
import SearchData
import Logger
import Networking
import DesignSystem

@main
struct SearchFeatureDemoApp: App {
    init() {
        // 커스텀 폰트(Pretendard) 등록. 없으면 applyWSSFont의 UIFont(name:)! 가 nil → 크래시.
        DesignSystemFontFamily.registerAllCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView()
        }
    }
}

// MARK: - Root: Mock ↔ 실서버 진입점 선택

// Demo가 App(DI) 역할을 대행해 UseCase를 조립한다.
// Mock = 인메모리(흐름 시연), 실서버 = NetworkingClient + 실제 Repository.
private struct DemoRootView: View {
    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    /// Mock 모드에서 최근 검색어 삭제가 실제로 반영되어 보이도록 공유하는 인메모리 저장소.
    private let demoRecentSearchStore = DemoRecentSearchStore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                NavigationLink("Mock으로 보기") { mockView }
                NavigationLink("실서버로 보기") { makeLiveView() }
                NavigationLink("상세탐색 필터 화면 단독 보기") { detailSearchFilterView }
            }
            .padding()
        }
    }

    /// 상세탐색 필터 화면(정보 탭) 단독 진입 — UseCase가 없어 Mock/실서버 구분 없이 바로 열 수 있다.
    private var detailSearchFilterView: some View {
        SearchFactory.makeDetailSearchFilterView { filter in
            consoleLogger.info("상세탐색 필터 확정: \(filter)")
        }
    }

    private var mockView: some View {
        SearchFactory.makeNormalSearchView(
            loadSosoPickUseCase: DemoLoadSosoPickUseCase(),
            loadRecentSearchWordsUseCase: DemoLoadRecentSearchWordsUseCase(store: demoRecentSearchStore),
            removeRecentSearchWordUseCase: DemoRemoveRecentSearchWordUseCase(store: demoRecentSearchStore),
            clearRecentSearchWordsUseCase: DemoClearRecentSearchWordsUseCase(store: demoRecentSearchStore),
            searchAutoCompletionWordsUseCase: DemoSearchAutoCompletionWordsUseCase(),
            searchNovelUseCase: DemoSearchNovelUseCase(),
            loadPopularKeywordsUseCase: DemoLoadPopularKeywordsUseCase(),
            logger: consoleLogger
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - 실서버 조립

    // NetworkingConfig.baseURL로 호출하고, DemoSessionTokenStore가 TEST_API_KEY를
    // accessToken으로 제공해 .requireToken 엔드포인트를 인증한다.
    @MainActor
    private func makeLiveView() -> some View {
        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )
        let recommendationRepository = RecommendationDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "RecommendationData", underlying: consoleLogger)
        )
        let searchRepository = SearchDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "SearchData", underlying: consoleLogger)
        )
        let keywordRepository = KeywordDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "BaseData", underlying: consoleLogger)
        )
        return SearchFactory.makeNormalSearchView(
            loadSosoPickUseCase: DefaultLoadSosoPickUseCase(recommendationRepository: recommendationRepository),
            loadRecentSearchWordsUseCase: DefaultLoadRecentSearchWordsUseCase(recentSearchRepository: searchRepository),
            removeRecentSearchWordUseCase: DefaultRemoveRecentSearchWordUseCase(recentSearchRepository: searchRepository),
            clearRecentSearchWordsUseCase: DefaultClearRecentSearchWordsUseCase(recentSearchRepository: searchRepository),
            searchAutoCompletionWordsUseCase: DefaultSearchAutoCompletionWordsUseCase(searchAutoCompletionRepository: searchRepository),
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: searchRepository),
            loadPopularKeywordsUseCase: DefaultLoadPopularKeywordsUseCase(keywordRepository: keywordRepository),
            logger: consoleLogger
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Demo UseCase (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요).

private struct DemoLoadSosoPickUseCase: LoadSosoPickUseCase {
    func execute() async throws(RepositoryError) -> [SosoPick] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return (1...10).map { number in
            SosoPick(
                novelID: NovelID(number),
                novelTitle: "소소픽 데모 작품 \(number)",
                novelThumbnailimage: URL(string: "https://i.pinimg.com/1200x/40/cb/df/40cbdfcce149156643cc6eae5e0dec6f.jpg")
            )
        }
    }
}

/// Mock UseCase 3개가 공유하는 인메모리 최근 검색어 목록.
private final class DemoRecentSearchStore {
    var words: [RecentSearchWord] = (1...5).map { number in
        RecentSearchWord(id: SearchWordID(number), title: "데모 검색어 \(number)")
    }
}

private struct DemoLoadRecentSearchWordsUseCase: LoadRecentSearchWordsUseCase {
    let store: DemoRecentSearchStore

    func execute() async throws(RepositoryError) -> [RecentSearchWord] {
        store.words
    }
}

private struct DemoRemoveRecentSearchWordUseCase: RemoveRecentSearchWordUseCase {
    let store: DemoRecentSearchStore

    func execute(word: RecentSearchWord) async throws(RepositoryError) {
        store.words.removeAll { $0.id == word.id }
    }
}

private struct DemoClearRecentSearchWordsUseCase: ClearRecentSearchWordsUseCase {
    let store: DemoRecentSearchStore

    func execute() async throws(RepositoryError) {
        store.words = []
    }
}

private struct DemoSearchAutoCompletionWordsUseCase: SearchAutoCompletionWordsUseCase {
    func execute(searchText: String) async throws(RepositoryError) -> [SearchAutoCompletionWord] {
        try? await Task.sleep(nanoseconds: 200_000_000)
        return [
            SearchAutoCompletionWord(word: "\(searchText) 데모 자동완성 1"),
            SearchAutoCompletionWord(word: "\(searchText) 데모 자동완성 2"),
            SearchAutoCompletionWord(word: "\(searchText) 데모 자동완성 3")
        ]
    }
}

private struct DemoSearchNovelUseCase: SearchNovelUseCase {
    /// Mock에서도 무한스크롤을 시연할 수 있도록 3페이지(0~2)까지는 채워서 반환하고 그 뒤로는 hasNext를 끈다.
    private static let demoPageCount = 3

    func searchByText(_ query: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard page < Self.demoPageCount else {
            return (Paginated(items: [], hasNext: false), 5 * Self.demoPageCount)
        }
        let novels = (1...5).map { number in
            let sequence = page * 5 + number
            return Novel(
                id: NovelID(sequence),
                thumbnailImage: URL(string: "https://i.pinimg.com/1200x/40/cb/df/40cbdfcce149156643cc6eae5e0dec6f.jpg"),
                title: "\(query) 데모 검색결과 \(sequence)",
                authors: ["데모 작가 \(sequence)"],
                genres: [],
                interestCount: sequence * 3,
                rating: 4.5,
                ratingCount: sequence,
                isInterested: false
            )
        }
        return (Paginated(items: novels, hasNext: page < Self.demoPageCount - 1), 5 * Self.demoPageCount)
    }

    func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard page < Self.demoPageCount else {
            return (Paginated(items: [], hasNext: false), 4 * Self.demoPageCount)
        }
        let novels = (1...4).map { number in
            let sequence = page * 4 + number
            return Novel(
                id: NovelID(sequence),
                thumbnailImage: URL(string: "https://i.pinimg.com/1200x/40/cb/df/40cbdfcce149156643cc6eae5e0dec6f.jpg"),
                title: "필터 데모 검색결과 \(sequence)",
                authors: ["데모 작가 \(sequence)"],
                genres: [],
                interestCount: sequence * 3,
                rating: 4.5,
                ratingCount: sequence,
                isInterested: false
            )
        }
        return (Paginated(items: novels, hasNext: page < Self.demoPageCount - 1), 4 * Self.demoPageCount)
    }
}

private struct DemoLoadPopularKeywordsUseCase: LoadPopularKeywordsUseCase {
    func execute() async throws(RepositoryError) -> PopularKeywords {
        PopularKeywords(
            keywords: ["이세계", "회귀", "환생", "빙의", "먼치킨", "집착", "복수"].enumerated().map { index, name in
                Keyword(id: KeywordID(index + 1), name: name)
            }
        )
    }
}
