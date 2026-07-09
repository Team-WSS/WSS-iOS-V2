//
//  NovelDetailFeatureDemoApp.swift
//  NovelDetailFeatureDemo
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import NovelDetailFeature
import BaseDomain
import NovelDomain
import FeedDomain
import BaseData
import NovelData
import FeedData
import Logger
import Networking
import DesignSystem

@main
struct NovelDetailFeatureDemoApp: App {
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

    private let novelID = NovelID(1)

    @State private var dataSource: DataSource = .mock
    @State private var isDetailPresented = false
    /// 열 때마다 증가. detailView의 .id에 물려 매 진입마다 새 ViewModel이 만들어지게 한다.
    @State private var detailOpenCount = 0

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Button("작품 상세 화면 열기") {
                    detailOpenCount += 1
                    isDetailPresented = true
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("WSS Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isDetailPresented) {
                detailView
                    .id(detailOpenCount)
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch dataSource {
        case .mock:
            NovelDetailFactory.makeView(
                novelID: novelID,
                loadNovelUseCase: DemoLoadNovelUseCase(),
                novelInterestUseCase: DemoNovelInterestUseCase(),
                loadNovelFeedsUseCase: DemoLoadNovelFeedsUseCase(),
                logger: consoleLogger,
                onReviewTapped: handleReviewTapped
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
        let novelRepository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: UserDefaultsStorage(),
            logger: DataLogger(moduleName: "NovelData", underlying: consoleLogger)
        )
        let keywordRepository = KeywordDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "BaseData", underlying: consoleLogger)
        )
        let feedRepository = FeedDataFactory.makeFeedRepository(
            client: client,
            logger: DataLogger(moduleName: "FeedData", underlying: consoleLogger)
        )
        return NovelDetailFactory.makeView(
            novelID: novelID,
            loadNovelUseCase: DefaultLoadNovelUseCase(
                novelRepository: novelRepository,
                keywordRepository: keywordRepository
            ),
            novelInterestUseCase: DefaultNovelInterestUseCase(novelRepository: novelRepository),
            loadNovelFeedsUseCase: DefaultLoadNovelFeedsUseCase(feedRepository: feedRepository),
            logger: consoleLogger,
            onReviewTapped: handleReviewTapped
        )
    }

    /// 작품 평가 진입 콜백. 실제 앱은 App 조정 계층이 NovelReviewFactory로 전환한다 — Demo는 로그만.
    private func handleReviewTapped(_ information: NovelInformation) {
        consoleLogger.info("작품 평가 진입 요청: \(information.novel.title)")
    }
}

// MARK: - Demo UseCases (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요).

private struct DemoLoadNovelUseCase: LoadNovelUseCase {
    func execute(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return NovelInformation(
            novel: Novel(
                id: id,
                thumbnailImage: nil,
                title: "당신의 이해를 돕기 위하여",
                authors: ["이보라"],
                genres: [.romanceFantasy],
                interestCount: 128,
                rating: 4.4,
                ratingCount: 52,
                isInterested: false
            ),
            feedCount: 3,
            genres: [.romanceFantasy],
            publicationStatus: .onGoing,
            userReview: nil,
            description: "이해할 수 없는 세계에서, 이해받고 싶은 마음들이 만난다. 소소한 독자들이 사랑한 로맨스 판타지.",
            platforms: [],
            attractivePoints: [.character, .vibe],
            keywords: [],
            readingStatusCount: [.watching: 12, .watched: 40, .quit: 3]
        )
    }
}

private struct DemoNovelInterestUseCase: NovelInterestUseCase {
    func add(id: NovelID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }

    func remove(id: NovelID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

private struct DemoLoadNovelFeedsUseCase: LoadNovelFeedsUseCase {
    func execute(novelID: NovelID,
                 lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        try? await Task.sleep(nanoseconds: 500_000_000)
        // 커서 0 = 첫 페이지, 이후 커서 = 마지막 피드 ID → 두 페이지로 페이지네이션을 시연한다.
        if lastFeedID.value == 0 {
            return Paginated(items: (1...10).map(makeFeed), hasNext: true)
        } else {
            return Paginated(items: (11...15).map(makeFeed), hasNext: false)
        }
    }

    private func makeFeed(_ number: Int) -> TotalFeed {
        TotalFeed(
            feedId: FeedID(number),
            createdDate: "3월 \(number)일",
            content: "데모 피드 \(number) — 이 작품 정말 소소하게 재밌네요.",
            author: Author(nickname: "소소한 독자 \(number)", profileImage: nil),
            likeCount: number,
            isLiked: false,
            commentCount: 0,
            isSpoiler: false,
            isModified: false,
            isPublic: true,
            imageCount: 0
        )
    }
}
