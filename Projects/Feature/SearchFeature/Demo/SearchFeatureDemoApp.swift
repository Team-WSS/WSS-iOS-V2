//
//  SearchFeatureDemoApp.swift
//  SearchFeatureDemo
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

// #185: 상세탐색 필터 화면의 "키워드" 탭 콘텐츠(KeywordTabContentBuilder)를 여기서 실제로 조립한다
// (App 역할 대행 — Feature 간 직접 의존은 Demo 타깃에서만 허용, SearchFeature Sources는 KeywordFeature를 모른다).
import KeywordFeature
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
                NavigationLink("상세탐색 진입(실서버)") {
                    DetailSearchDemoFlow(
                        keywordTabContent: makeLiveKeywordTabContent(),
                        makeResultView: makeLiveDetailSearchResultView(filter:)
                    )
                }
            }
            .padding()
        }
    }

    /// "키워드" 탭 콘텐츠 조립 — `KeywordFeatureFactory.makeSearchKeywordView`는 자체 액션바가 없어 그대로
    /// 감싸면 된다. 어떤 UseCase(Mock/실서버)를 쓸지는 호출부가 결정 — Mock/실서버 흐름에 맞춰 카탈로그
    /// 출처도 함께 바뀌도록(#185) 여기서 고정하지 않는다.
    private func keywordTabContentBuilder(
        loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase,
        searchKeywordsUseCase: SearchKeywordsUseCase
    ) -> KeywordTabContentBuilder {
        { initialKeywords, onSelectionChanged in
            AnyView(
                KeywordFeatureFactory.makeSearchKeywordView(
                    loadTotalKeywordsUseCase: loadTotalKeywordsUseCase,
                    searchKeywordsUseCase: searchKeywordsUseCase,
                    initialSelectedKeywords: initialKeywords,
                    onSelectionChanged: onSelectionChanged,
                    logger: consoleLogger
                )
            )
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

    /// "상세탐색 필터 화면 단독 보기"의 키워드 탭 전용 실서버 조립 — `makeLiveView()`와 별개 `NetworkingClient`를
    /// 새로 만든다(이 파일의 기존 관행대로 진입점마다 독립적으로 조립, 공유 캐시 없음).
    @MainActor
    private func makeLiveKeywordTabContent() -> KeywordTabContentBuilder {
        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )
        let keywordRepository = KeywordDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "BaseData", underlying: consoleLogger)
        )
        return keywordTabContentBuilder(
            loadTotalKeywordsUseCase: DefaultFetchTotalKeywordsUseCase(keywordRepository: keywordRepository),
            searchKeywordsUseCase: DefaultSearchKeywordUseCase(keywordRepository: keywordRepository)
        )
    }

    /// "상세탐색 진입"에서 "작품 찾기" 확정 후 이어지는 실제 검색 결과 화면(`DetailSearchDemoFlow`가 push).
    @MainActor
    private func makeLiveDetailSearchResultView(filter: SearchFilter) -> some View {
        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )
        let searchRepository = SearchDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "SearchData", underlying: consoleLogger)
        )
        return SearchFactory.makeDetailSearchResultView(
            filter: filter,
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: searchRepository),
            logger: consoleLogger
        )
    }
}

/// `.navigationDestination(item:)`용 얇은 래퍼 — "상세탐색 진입"에서 "작품 찾기"를 누르면 실제 검색 결과
/// 화면(`DetailSearchResultView`, 실서버)을 push하도록 값을 태운다(`NormalSearchView`의
/// `DetailSearchNavigation`과 동일 패턴).
private struct DemoDetailSearchResult: Hashable {
    let id = UUID()
    let filter: SearchFilter

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// "상세탐색" 자체의 진입점(#185) — 필터 화면이 스택의 첫 화면이고, "작품 찾기" 확정 시 결과 화면을 그
/// **위에 새로 push**한다(뒤로가기 하면 필터로 돌아옴). `DetailSearchResultView`의 필터 pill 경유(기존
/// 결과 화면으로 되돌아감, `DetailSearchResultView.swift` 참고)와는 확정 후 동작이 정반대라 — 그래서
/// `DetailSearchFilterView`가 확정 시 스스로 pop하지 않도록 바뀌었고(호출부 책임), 이 화면은 pop 대신
/// 그냥 `result`를 채워 결과 화면을 앞으로 쌓는다.
private struct DetailSearchDemoFlow: View {
    let keywordTabContent: KeywordTabContentBuilder
    let makeResultView: (SearchFilter) -> AnyView

    @State private var result: DemoDetailSearchResult?

    init(keywordTabContent: @escaping KeywordTabContentBuilder, makeResultView: @escaping (SearchFilter) -> some View) {
        self.keywordTabContent = keywordTabContent
        self.makeResultView = { AnyView(makeResultView($0)) }
    }

    var body: some View {
        SearchFactory.makeDetailSearchFilterView(
            filter: SearchFilter(),
            keywordTabContent: keywordTabContent
        ) { filter in
            result = DemoDetailSearchResult(filter: filter)
        }
        .navigationDestination(item: $result) { result in
            makeResultView(result.filter)
        }
    }
}

// MARK: - 키워드 탭 데모 UseCase (Mock)

/// 상세탐색 필터의 "키워드" 탭 진입용 인메모리 카테고리 목록 — `SearchKeywordsUseCase.execute`는 전체 목록에서
/// 이름으로 필터링해 흉내낸다(서버 없이 브라우징+검색 둘 다 시연).
private struct DemoLoadTotalKeywordsUseCase: LoadTotalKeywordsUseCase {
    func execute() async throws(RepositoryError) -> [KeywordGroup] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return [
            KeywordGroup(category: .worldview, keywords: ["이세계", "현대", "SF"].demoKeywords(offset: 0)),
            KeywordGroup(category: .material, keywords: ["환생", "빙의", "회귀"].demoKeywords(offset: 10)),
            KeywordGroup(category: .character, keywords: ["먼치킨", "천재", "악당"].demoKeywords(offset: 20)),
            KeywordGroup(category: .relationship, keywords: ["친구", "라이벌", "첫사랑"].demoKeywords(offset: 30)),
            KeywordGroup(category: .vibe, keywords: ["힐링되는", "반전있는", "탄탄한"].demoKeywords(offset: 40))
        ]
    }
}

private struct DemoSearchKeywordsUseCase: SearchKeywordsUseCase {
    func execute(searchText: String) async throws(RepositoryError) -> [Keyword] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        let allGroups = try await DemoLoadTotalKeywordsUseCase().execute()
        return allGroups.flatMap(\.keywords).filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

private extension [String] {
    func demoKeywords(offset: Int) -> [Keyword] {
        enumerated().map { index, name in Keyword(id: KeywordID(offset + index), name: name) }
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
