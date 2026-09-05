//
//  HomeFeatureDemoApp.swift
//  HomeFeatureDemo
//
//  Created by YunhakLee on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import HomeFeature
import BaseDomain
import RecommendationDomain
import NotificationDomain
import BaseData
import RecommendationData
import NotificationData
import Logger
import Networking
import PushAuthorization
import DesignSystem

@main
struct HomeFeatureDemoApp: App {
    init() {
        // 커스텀 폰트(Pretendard) 등록. 없으면 applyWSSFont의 UIFont(name:)! 가 nil → 크래시.
        // 프리뷰는 이 Demo 앱을 호스트로 띄우므로 여기서 등록하면 프리뷰도 함께 해결된다.
        DesignSystemFontFamily.registerAllCustomFonts()

        // 닉네임은 서버가 아니라 로컬 캐시에서 온다 — 실제 앱은 로그인·프로필 조회가 채우지만
        // Demo는 그 경로를 안 거치므로 직접 심어야 추천글 제목의 "{닉네임}님을" 이 확인된다.
        // (body 평가 중 부수효과가 되지 않도록 앱 시작 시점에 한 번만 쓴다.)
        UserDefaultsStorage().set(.nickname, "웹소소")
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView()
        }
    }
}

/// 홈 Mock 시나리오 — **버튼 하나 = 데이터 조건 하나**(NovelDetailFeature Demo 규약).
/// 실서버 모드에선 무시되고 실제 응답을 그린다.
private enum DemoHomeScenario: String, CaseIterable, Identifiable {
    case filled = "정상"
    /// 선호장르 미설정 — 그리드 대신 설정 유도 CTA가 뜨는 축(Figma 두 번째 시안).
    case noGenre = "장르미설정"
    /// 오늘의 발견·추천글이 0건 — 섹션이 통째로 빌 때의 레이아웃 축.
    case empty = "빈 데이터"
    /// 로드 실패 3종 — NetworkErrorView 문구가 RepositoryError 3분류(서버/네트워크/일시)로 갈리는 걸 확인하는 축(#244).
    case failureServer = "실패-서버"
    case failureNetwork = "실패-네트워크"
    case failureGeneral = "실패-일시"
    case authExpired = "인증만료"
    var id: String { rawValue }
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

    /// 시스템 푸시 권한 상태(#193) — 서버 데이터와 무관해 `scenario`와 별개 축으로 둔다.
    private enum PushAuthorizationScenario: String, CaseIterable, Identifiable {
        case authorized = "허용됨"
        case notDetermined = "notDetermined"
        case denied = "denied"
        var id: String { rawValue }

        var status: PushAuthorizationStatus {
            switch self {
            case .authorized:    .authorized
            case .notDetermined: .notDetermined
            case .denied:        .denied
            }
        }
    }

    @State private var dataSource: DataSource = .mock
    @State private var scenario: DemoHomeScenario = .filled
    @State private var pushAuthorizationScenario: PushAuthorizationScenario = .authorized
    /// 소스·시나리오 전환 시 화면 정체성을 갈아 새 ViewModel(깨끗한 로드)을 강제한다.
    private var homeViewID: String { "\(dataSource.rawValue)-\(scenario.rawValue)-\(pushAuthorizationScenario.rawValue)" }

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        VStack(spacing: 0) {
            Picker("데이터 소스", selection: $dataSource) {
                ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            Picker("푸시 권한 시나리오", selection: $pushAuthorizationScenario) {
                ForEach(PushAuthorizationScenario.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            if dataSource == .mock {
                scenarioRow
            }

            homeView
                .id(homeViewID)
        }
    }

    private var scenarioRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DemoHomeScenario.allCases) { item in
                    Button(item.rawValue) { scenario = item }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(scenario == item ? .accentColor : .gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var homeView: some View {
        switch dataSource {
        case .mock:
            makeHomeView(
                loadHomeDataUseCase: DemoLoadHomeDataUseCase(scenario: scenario),
                loadUnreadNotificationStatusUseCase: DemoLoadUnreadNotificationStatusUseCase(scenario: scenario)
            )
        case .live:
            makeLiveView()
        }
    }

    // MARK: - 조립

    @MainActor
    private func makeHomeView(
        loadHomeDataUseCase: LoadHomeDataUseCase,
        loadUnreadNotificationStatusUseCase: LoadUnreadNotificationStatusUseCase
    ) -> some View {
        HomeFeatureFactory.makeView(
            loadHomeDataUseCase: loadHomeDataUseCase,
            loadUnreadNotificationStatusUseCase: loadUnreadNotificationStatusUseCase,
            pushAuthorizationChecker: DemoPushAuthorizationChecker(status: pushAuthorizationScenario.status),
            logger: consoleLogger,
            onNovelSelected: { consoleLogger.info("작품 상세 진입 요청: \($0)") },
            onFeedSelected: { consoleLogger.info("피드 상세 진입 요청: \($0)") },
            onSearchTapped: { consoleLogger.info("검색 진입 요청") },
            onDetailSearchTapped: { consoleLogger.info("상세 검색 진입 요청") },
            onNotificationTapped: { consoleLogger.info("알림 진입 요청") },
            onPreferenceGenreSettingTapped: { consoleLogger.info("선호장르 설정 진입 요청") },
            onAuthenticationRequired: { consoleLogger.info("인증 만료 → 로그인 진입 요청") }
        )
    }

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
        let notificationRepository = NotificationDataFactory.makeNotificationRepository(
            client: client,
            logger: DataLogger(moduleName: "NotificationData", underlying: consoleLogger)
        )

        return makeHomeView(
            loadHomeDataUseCase: DefaultLoadHomeDataUseCase(repository: recommendationRepository),
            loadUnreadNotificationStatusUseCase: DefaultLoadUnreadNotificationStatusUseCase(
                repository: notificationRepository
            )
        )
    }
}

// MARK: - Demo UseCases (Mock)

/// 시스템 권한 상태를 실제로 조회하지 않고 Demo 화면에서 고른 시나리오를 그대로 돌려준다(#193).
/// `dataSource`가 `.mock`이든 `.live`든 공용으로 쓴다 — 이 값은 서버가 아니라 iOS 설정에서 오기 때문.
private struct DemoPushAuthorizationChecker: PushAuthorizationChecker {
    let status: PushAuthorizationStatus

    func authorizationStatus() async -> PushAuthorizationStatus { status }

    func requestAuthorization() async -> Bool {
        // 실제 시스템 프롬프트 대신 "허용함"으로 시연한다(Demo는 알림 권한을 실제로 요청하지 않음).
        true
    }
}

private struct DemoLoadHomeDataUseCase: LoadHomeDataUseCase {

    let scenario: DemoHomeScenario

    func execute() async throws(RepositoryError) -> HomeData {
        try? await Task.sleep(nanoseconds: 500_000_000)

        switch scenario {
        case .failureServer:   throw .serverUnavailable
        case .failureNetwork:  throw .networkUnavailable
        case .failureGeneral:  throw .unknown
        case .authExpired:  throw .authenticationRequired
        case .empty:
            return HomeData(
                nickname: "일이삼사오육칠팔구십",
                todayDiscoveries: [],
                trendingFeeds: [],
                preferenceGenreNovelState: .novels([])
            )
        case .noGenre:
            return HomeData(
                nickname: "일이삼사오육칠팔구십",
                todayDiscoveries: DemoHomeData.todayDiscoveries,
                trendingFeeds: DemoHomeData.trendingFeeds,
                preferenceGenreNovelState: .noGenreSettings
            )
        case .filled:
            return HomeData(
                nickname: "일이삼사오육칠팔구십",
                todayDiscoveries: DemoHomeData.todayDiscoveries,
                trendingFeeds: DemoHomeData.trendingFeeds,
                preferenceGenreNovelState: .novels(DemoHomeData.preferenceGenreNovels)
            )
        }
    }
}

private struct DemoLoadUnreadNotificationStatusUseCase: LoadUnreadNotificationStatusUseCase {

    let scenario: DemoHomeScenario

    func execute() async throws(RepositoryError) -> UnreadNotificationStatus {
        switch scenario {
        case .failureServer:   throw .serverUnavailable
        case .failureNetwork:  throw .networkUnavailable
        case .failureGeneral:  throw .unknown
        case .authExpired:  throw .authenticationRequired
        default:            return UnreadNotificationStatus(hasUnreadNotifications: true)
        }
    }
}

private enum DemoHomeData {

    /// 실서버가 3건을 준다. 작품 소개 카드와 유저 한마디 카드가 섞이고,
    /// 키워드가 0개인 작품도 실제로 온다 → 칩이 없는 카드까지 한 화면에서 확인한다.
    static let todayDiscoveries: [TodayDiscovery] = [
        TodayDiscovery(
            novelID: NovelID(187),
            novelTitle: "일이삼사오육칠팔구십일이삼사오육칠팔구십",
            novelThumbnailImage: URL(string: "https://picsum.photos/seed/wss1/216/320"),
            novelAuthor: "일이삼사오육칠팔구십",
            novelGenre: .BL,
            publicationStatus: .onGoing,
            keywords: ["사랑꾼", "짝사랑"],
            content: .novel,
            contentDescription: "며칠째 아파트 주차장을 서성이는 작은 고양이가 설국화의 눈에 밟힌다. 삐쩍 마른 몸에 눈도 뜨지 못하는 모습이 설국화의 측은지심을 자극한다."
        ),
        TodayDiscovery(
            novelID: NovelID(4217),
            novelTitle: "괴담에 떨어져도 출근을 해야 하는구나",
            novelThumbnailImage: URL(string: "https://picsum.photos/seed/wss2/216/320"),
            novelAuthor: "백덕수",
            novelGenre: .modernFantasy,
            publicationStatus: .completed,
            keywords: ["동양풍/사극", "학원/아카데미"],
            // ⚠️ 아바타를 nil로 두지 말 것 — 유저 한마디 카드면 서버가 `avatarImage`를 **반드시** 준다
            // (`RecommendationMapper`가 닉네임·아바타 중 한쪽만 오면 매핑을 실패시킨다).
            // nil로 두면 실서버엔 없는 "회색 네모 + 닉네임" 상태를 Demo가 그린다.
            content: .userComment(
                user: Author(userId: UserID(1),
                             nickname: "천마",
                             profileImage: URL(string: "https://picsum.photos/seed/wssuser1/96/96"))
            ),
            contentDescription: "왕실에는 막대한 빚이 있었고, 그들은 빚을 갚기 위해 왕녀인 바이올렛을 막대한 돈을 지녔지만 공작의 사생아인 윈터에게 시집보내기로 한다."
        ),
        TodayDiscovery(
            novelID: NovelID(4640),
            novelTitle: "죽음을 삽니다",
            novelThumbnailImage: nil,
            novelAuthor: "유진성",
            novelGenre: .drama,
            publicationStatus: .onGoing,
            keywords: [],
            content: .novel,
            contentDescription: "짧은 소개글."
        )
    ]

    /// 실서버가 정확히 6건을 준다(2개씩 3페이지). 스포일러 글을 섞어 대체 문구도 함께 확인한다.
    static let trendingFeeds: [TrendingFeed] = (1...6).map { index in
        TrendingFeed(
            feedID: FeedID(index),
            novelTitle: index.isMultiple(of: 2)
                ? "일이삼사오육칠팔구십일이삼사오육칠팔구십"
                : "우아한 오브리 \(index)",
            novelThumbnailImage: URL(string: "https://picsum.photos/seed/feed\(index)/216/320"),
            novelGenre: NovelGenre.allCases[index % NovelGenre.allCases.count],
            description: index.isMultiple(of: 3)
                ? "이름이 나여주입니다ㅋㅋㅋ읽던 소설이 세계멸망엔딩나서 댓글달았다가 그 세계의 본인에게 빙의하게 되었는데 S급 힐러라서 살아남을 수 있을까요"
                : "역대급임",
            isSpoiler: index.isMultiple(of: 4),
            likeCount: index * 3,
            commentCount: index
        )
    }

    static let preferenceGenreNovels: [PreferenceGenreNovel] = (1...8).map { index in
        PreferenceGenreNovel(
            novelID: NovelID(index),
            novelTitle: index.isMultiple(of: 2)
                ? "여주인공의 오빠를 지키는 방법 \(index)"
                : "신데렐라는 이 멧밭쥐가 데려갑니다",
            novelThumbnailImage: index.isMultiple(of: 5)
                ? nil
                : URL(string: "https://picsum.photos/seed/taste\(index)/216/320"),
            novelAuthors: index.isMultiple(of: 3) ? ["이보라", "킨"] : ["이보라"],
            interestCount: 23,
            ratingCount: 2,
            rating: 4.0
        )
    }
}
