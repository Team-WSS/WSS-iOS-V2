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
import FeedDomain
import NovelDomain
import BaseData
import FeedData
import NovelData
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
                onReviewTapped: handleReviewTapped,
                onCreateFeedTapped: handleCreateFeedTapped
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
            onReviewTapped: handleReviewTapped,
            onCreateFeedTapped: handleCreateFeedTapped
        )
    }

    /// 작품 평가 진입 콜백. 실제 앱은 App 조정 계층이 NovelReviewFactory로 전환한다 — Demo는 로그만.
    private func handleReviewTapped(_ information: NovelInformation, _ status: ReadingStatus) {
        consoleLogger.info("작품 평가 진입 요청: \(information.novel.title) / seed 상태: \(status)")
    }

    /// 피드 작성 진입 콜백. 실제 앱은 App 조정 계층이 CreateFeed로 전환한다 — Demo는 로그만.
    private func handleCreateFeedTapped() {
        consoleLogger.info("피드 작성 진입 요청")
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
                thumbnailImage: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
                title: "당신의 이해를 돕기 위하여",
                authors: ["이보라"],
                genres: [.romanceFantasy, .romance],
                interestCount: 128,
                rating: 4.4,
                ratingCount: 52,
                isInterested: false
            ),
            feedCount: 3,
            genres: [.romanceFantasy, .romance],
            publicationStatus: .completed,
            userReview: UserNovelReview(
                readingStatus: .watching,
                rating: try? Rating(4.0),
                attractivePoint: [.character, .vibe],
                period: try? ReadingPeriod(start: Date(timeIntervalSinceNow: -86_400 * 300), end: nil),
                keywords: []
            ),
            description: "왕실에는 막대한 빚이 있었고, 그들은 빚을 갚기 위해 왕녀인 바이올렛을 막대한 돈을 지녔지만 공작의 사생아인 윈터에게 시집보낸다. 계약 결혼으로 시작된 두 사람의 이야기.",
            platforms: [
                URL(string: "https://novel.naver.com").map {
                    NovelPlatform(name: "네이버시리즈", image: nil, url: $0)
                },
                URL(string: "https://page.kakao.com").map {
                    NovelPlatform(name: "카카오페이지", image: nil, url: $0)
                }
            ].compactMap { $0 },
            attractivePoints: [.character, .relationship, .writingSkill],
            keywords: [
                NovelKeyword(keyword: Keyword(id: KeywordID(1), name: "피폐"), count: 7),
                NovelKeyword(keyword: Keyword(id: KeywordID(2), name: "정치물"), count: 5),
                NovelKeyword(keyword: Keyword(id: KeywordID(3), name: "궁중암투"), count: 3),
                NovelKeyword(keyword: Keyword(id: KeywordID(4), name: "빙의"), count: 2),
                NovelKeyword(keyword: Keyword(id: KeywordID(5), name: "후회"), count: 2)
            ],
            readingStatusCount: [.watching: 130, .watched: 10, .quit: 100]
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
