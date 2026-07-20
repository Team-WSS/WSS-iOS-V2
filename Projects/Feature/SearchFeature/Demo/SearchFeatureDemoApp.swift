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

// MARK: - Root: Mock ↔ 실서버 토글

// Demo가 App(DI) 역할을 대행해 UseCase를 조립한다.
// Mock = 인메모리(흐름 시연), 실서버 = NetworkingClient + 실제 Repository.
private struct DemoRootView: View {
    private enum DataSource: String, CaseIterable, Identifiable {
        case mock = "Mock"
        case live = "실서버"
        var id: String { rawValue }
    }

    @State private var dataSource: DataSource = .mock

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                searchView
            }
        }
    }

    /// Mock 모드에서 최근 검색어 삭제가 실제로 반영되어 보이도록 공유하는 인메모리 저장소.
    private let demoRecentSearchStore = DemoRecentSearchStore()

    @ViewBuilder
    private var searchView: some View {
        switch dataSource {
        case .mock:
            SearchFactory.makeView(
                loadSosoPickUseCase: DemoLoadSosoPickUseCase(),
                loadRecentSearchWordsUseCase: DemoLoadRecentSearchWordsUseCase(store: demoRecentSearchStore),
                removeRecentSearchWordUseCase: DemoRemoveRecentSearchWordUseCase(store: demoRecentSearchStore),
                clearRecentSearchWordsUseCase: DemoClearRecentSearchWordsUseCase(store: demoRecentSearchStore),
                logger: consoleLogger
            )
        case .live:
            makeLiveView()
        }
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
        return SearchFactory.makeView(
            loadSosoPickUseCase: DefaultLoadSosoPickUseCase(recommendationRepository: recommendationRepository),
            loadRecentSearchWordsUseCase: DefaultLoadRecentSearchWordsUseCase(recentSearchRepository: searchRepository),
            removeRecentSearchWordUseCase: DefaultRemoveRecentSearchWordUseCase(recentSearchRepository: searchRepository),
            clearRecentSearchWordsUseCase: DefaultClearRecentSearchWordsUseCase(recentSearchRepository: searchRepository),
            logger: consoleLogger
        )
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
