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
    /// 열 때마다 증가. createView의 .id에 물려 매 진입마다 새 ViewModel이 만들어지게 한다.
    @State private var createOpenCount = 0

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

                Spacer()
            }
            .padding()
            .navigationTitle("WSS Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isCreatePresented) {
                createView
                    .id(createOpenCount)
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
        userDefaults.set(.userID, 10041)
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
