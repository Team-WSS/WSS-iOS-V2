//
//  CollectionFeatureDemoApp.swift
//  CollectionFeatureDemo
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CollectionFeature
import BaseDomain
import CollectionDomain
import SearchDomain
import NovelDomain
import BaseData
import CollectionData
import SearchData
import NovelData
import Logger
import Networking
import DesignSystem

@main
struct CollectionFeatureDemoApp: App {
    init() {
        // 커스텀 폰트(Pretendard) 등록. 없으면 applyWSSFont의 UIFont(name:)! 가 nil → 크래시.
        // 프리뷰는 이 Demo 앱을 호스트로 띄우므로 여기서 등록하면 프리뷰도 함께 해결된다.
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
    @State private var isCreatePresented = false
    @State private var isListPresented = false
    /// 열 때마다 증가. createView/listView의 .id에 물려 매 진입마다 새 ViewModel이 만들어지게 한다.
    @State private var createOpenCount = 0
    @State private var listOpenCount = 0

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Button("컬렉션 생성 화면 열기") {
                    createOpenCount += 1
                    isCreatePresented = true
                }
                .buttonStyle(.borderedProminent)

                Button("컬렉션 목록 화면 열기") {
                    listOpenCount += 1
                    isListPresented = true
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            .navigationTitle("WSS Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isCreatePresented) {
                createView
                    .id(createOpenCount)
            }
            .navigationDestination(isPresented: $isListPresented) {
                listView
                    .id(listOpenCount)
            }
        }
    }

    @ViewBuilder
    private var createView: some View {
        switch dataSource {
        case .mock:
            CollectionFeatureFactory.makeCreateCollectionView(
                createCollectionUseCase: DemoCreateCollectionUseCase(),
                searchNovelUseCase: DemoSearchNovelUseCase(),
                loadMyLibraryUseCase: DemoLoadMyLibraryUseCase(),
                logger: consoleLogger,
                onAuthenticationRequired: handleAuthenticationRequired
            )
        case .live:
            makeLiveView()
        }
    }

    @ViewBuilder
    private var listView: some View {
        switch dataSource {
        case .mock:
            CollectionFeatureFactory.makeCollectionListView(
                userID: UserID(10049),
                loadCollectionsUseCase: DemoLoadCollectionsUseCase(),
                loadLikedCollectionsUseCase: DemoLoadLikedCollectionsUseCase(),
                createCollectionUseCase: DemoCreateCollectionUseCase(),
                searchNovelUseCase: DemoSearchNovelUseCase(),
                loadMyLibraryUseCase: DemoLoadMyLibraryUseCase(),
                logger: consoleLogger,
                onAuthenticationRequired: handleAuthenticationRequired
            )
        case .live:
            makeLiveListView()
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
        let repository = CollectionDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "CollectionData", underlying: consoleLogger)
        )
        let searchRepository = SearchDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "SearchData", underlying: consoleLogger)
        )
        // 서재 조회 — LibraryFeatureDemoApp의 실서버 배관과 동일(내 서재는 저장된 userID를 쓰므로
        // Demo가 직접 세팅). NovelData의 KeywordRepository도 함께 필요하다(DefaultLoadMyLibraryUseCase
        // 시그니처 참고).
        let userDefaults = UserDefaultsStorage()
        userDefaults.set(.userID, 10049)
        let novelRepository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: userDefaults,
            logger: DataLogger(moduleName: "NovelData", underlying: consoleLogger)
        )
        let keywordRepository = KeywordDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "BaseData", underlying: consoleLogger)
        )
        return CollectionFeatureFactory.makeCreateCollectionView(
            createCollectionUseCase: DefaultCreateCollectionUseCase(collectionRepository: repository),
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: searchRepository),
            loadMyLibraryUseCase: DefaultLoadMyLibraryUseCase(
                novelRepository: novelRepository,
                keywordRepository: keywordRepository
            ),
            logger: consoleLogger,
            onAuthenticationRequired: handleAuthenticationRequired
        )
    }

    @MainActor
    private func makeLiveListView() -> some View {
        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )
        let repository = CollectionDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "CollectionData", underlying: consoleLogger)
        )
        let searchRepository = SearchDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "SearchData", underlying: consoleLogger)
        )
        let userDefaults = UserDefaultsStorage()
        userDefaults.set(.userID, 10049)
        let novelRepository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: userDefaults,
            logger: DataLogger(moduleName: "NovelData", underlying: consoleLogger)
        )
        let keywordRepository = KeywordDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "BaseData", underlying: consoleLogger)
        )
        return CollectionFeatureFactory.makeCollectionListView(
            userID: UserID(10049),
            loadCollectionsUseCase: DefaultLoadCollectionsUseCase(collectionRepository: repository),
            loadLikedCollectionsUseCase: DefaultLoadLikedCollectionsUseCase(collectionRepository: repository),
            createCollectionUseCase: DefaultCreateCollectionUseCase(collectionRepository: repository),
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: searchRepository),
            loadMyLibraryUseCase: DefaultLoadMyLibraryUseCase(
                novelRepository: novelRepository,
                keywordRepository: keywordRepository
            ),
            logger: consoleLogger,
            onAuthenticationRequired: handleAuthenticationRequired
        )
    }

    /// 인증 만료 콜백. 실제 앱은 App 조정 계층이 로그인 화면으로 전환한다 — Demo는 로그만.
    private func handleAuthenticationRequired() {
        consoleLogger.info("인증 만료 → 로그인 진입 요청")
    }
}

// MARK: - Demo UseCase (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요).

private struct DemoCreateCollectionUseCase: CreateCollectionUseCase {
    func execute(_ draft: CollectionDraft) async throws(RepositoryError) -> CollectionID {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return CollectionID(1)
    }
}

private struct DemoSearchNovelUseCase: SearchNovelUseCase {
    /// Mock에서도 무한스크롤을 시연할 수 있도록 3페이지(0~2)까지는 채워서 반환하고 그 뒤로는 hasNext를
    /// 끈다(`SearchFeatureDemoApp.DemoSearchNovelUseCase`와 동일 관례).
    private static let demoPageCount = 3

    func searchByText(_ query: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard page < Self.demoPageCount else {
            return (Paginated(items: [], hasNext: false), 5 * Self.demoPageCount)
        }
        let novels = (1...5).map { number -> Novel in
            let sequence = page * 5 + number
            return Novel(
                id: NovelID(sequence),
                thumbnailImage: nil,
                title: "\(query) 검색 결과 작품 \(sequence)",
                authors: ["작가 \(sequence)"],
                genres: [],
                interestCount: 0,
                rating: 0,
                ratingCount: 0,
                isInterested: nil
            )
        }
        return (Paginated(items: novels, hasNext: page < Self.demoPageCount - 1), 5 * Self.demoPageCount)
    }

    func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        (Paginated(items: [], hasNext: false), 0)
    }
}

private struct DemoLoadMyLibraryUseCase: LoadMyLibraryUseCase {
    /// 무한스크롤을 시연할 수 있도록 3페이지까지는 채워서 반환하고 그 뒤로는 hasNext를 끈다
    /// (`DemoSearchNovelUseCase`와 동일 관례 — 다만 정수 page가 아니라 커서 문자열을 왕복한다).
    private static let demoPageCount = 3
    private static let pageSize = 9

    func execute(filter: MyLibraryFilter, cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        try? await Task.sleep(nanoseconds: 300_000_000)
        let pageIndex = cursor.flatMap(Int.init) ?? 0
        guard pageIndex < Self.demoPageCount else {
            return (CursorPaginated(items: [], hasNext: false, nextCursor: nil), Self.pageSize * Self.demoPageCount)
        }
        let novels = (1...Self.pageSize).map { number -> LibraryNovel in
            let sequence = pageIndex * Self.pageSize + number
            return LibraryNovel(
                id: NovelID(sequence),
                title: "내 서재 작품 \(sequence)",
                thumbnailImage: nil,
                rating: 4.0,
                isInterested: sequence.isMultiple(of: 3),
                userReview: sequence.isMultiple(of: 2)
                    ? UserNovelReview(
                        readingStatus: ReadingStatus.allCases[sequence % ReadingStatus.allCases.count],
                        rating: try? Rating(Double(sequence % 9 + 1) * 0.5),
                        attractivePoint: [],
                        period: nil,
                        keywords: []
                      )
                    : nil,
                writtenFeeds: []
            )
        }
        let hasNext = pageIndex < Self.demoPageCount - 1
        return (
            CursorPaginated(items: novels, hasNext: hasNext, nextCursor: hasNext ? String(pageIndex + 1) : nil),
            Self.pageSize * Self.demoPageCount
        )
    }
}

private struct DemoLoadCollectionsUseCase: LoadCollectionsUseCase {
    func execute(userID: UserID, cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return DemoCollectionCardPage.page(cursor: cursor, namePrefix: "내 컬렉션")
    }
}

private struct DemoLoadLikedCollectionsUseCase: LoadLikedCollectionsUseCase {
    func execute(cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return DemoCollectionCardPage.page(cursor: cursor, namePrefix: "좋아요한 컬렉션")
    }
}

/// 두 목록 Mock이 공유하는 페이지 생성기 — 무한스크롤(3페이지)·표지 오버플로 배지(recentNovels < novelCount)·
/// 비공개 태그·설명 없는 카드까지 `CollectionListView`의 주요 분기를 한 번씩 보여준다.
private enum DemoCollectionCardPage {
    static let pageSize = 6
    private static let demoPageCount = 3

    static func page(cursor: String?, namePrefix: String) -> (CursorPaginated<CollectionCard>, Int) {
        let pageIndex = cursor.flatMap(Int.init) ?? 0
        guard pageIndex < demoPageCount else {
            return (CursorPaginated(items: [], hasNext: false, nextCursor: nil), pageSize * demoPageCount)
        }
        let cards = (1...pageSize).map { number -> CollectionCard in
            let sequence = pageIndex * pageSize + number
            let novelCount = sequence.isMultiple(of: 3) ? 42 : sequence
            let recentNovels = (1...min(novelCount, 5)).map { index in
                CollectionNovel(
                    id: NovelID(sequence * 10 + index),
                    title: "작품 \(sequence)-\(index)",
                    author: "작가 \(sequence)",
                    thumbnailImage: nil
                )
            }
            return CollectionCard(
                id: CollectionID(sequence),
                name: "\(namePrefix) \(sequence)",
                description: sequence.isMultiple(of: 4) ? nil : "존잼 수준이 정도를 넘음",
                novelCount: novelCount,
                isPrivate: sequence.isMultiple(of: 2),
                recentNovels: recentNovels
            )
        }
        let hasNext = pageIndex < demoPageCount - 1
        return (
            CursorPaginated(items: cards, hasNext: hasNext, nextCursor: hasNext ? String(pageIndex + 1) : nil),
            pageSize * demoPageCount
        )
    }
}
