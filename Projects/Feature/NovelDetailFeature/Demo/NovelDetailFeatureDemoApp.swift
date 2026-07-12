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
import NovelReviewDomain
import SocialDomain
import BaseData
import FeedData
import NovelData
import NovelReviewData
import SocialData
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

// MARK: - Demo 시나리오

/// 정보 탭 "독자들의 감상평"을 이루는 세 요소 — 각각 값이 없으면 그 섹션만 사라진다.
private enum ReaderReviewPart: CaseIterable {
    case attractivePoints
    case keywords
    case readingStatus
}

/// 내 평가(UserNovelReview)의 **선택 항목** — 평가 상태바에서 각각 칩으로 나타난다.
/// 읽기 상태는 평가가 존재하면 반드시 있으므로 축이 아니다(그래서 "읽기 상태만" = 빈 집합).
private enum UserReviewPart: CaseIterable {
    case rating
    case period
}

/// Mock 진입 조건. 화면이 **데이터에 따라 분기하는 지점**만 골라 시나리오로 만든다
/// (조건부 섹션·빈 상태·실패 뷰). 필드 하나씩 다른 조합은 시나리오로 만들지 않는다 — 버튼만 늘고 볼 게 없다.
private enum DemoScenario: CaseIterable, Identifiable {
    /// 모든 섹션이 값을 가진 기본 상태.
    case full
    /// 내 평가 없음 → 평가 상태바 대신 읽기 상태 셀렉터.
    case noUserReview
    /// 내 평가에 읽기 상태만 → 별점·기간 칩이 둘 다 없다. (보는 중)
    case userReviewStatusOnly
    /// 별점 + 읽기 상태 → 기간 칩만 없다. (봤어요)
    case userReviewWithRating
    /// 기간 + 읽기 상태 → 별점 칩만 없다. (하차)
    case userReviewWithPeriod
    /// 별점 + 기간 + 읽기 상태 → 칩 둘 다 있음. (봤어요)
    case userReviewWithRatingAndPeriod
    /// 매력포인트만 없음 → 정보 탭 감상평에서 그 섹션만 사라진다(키워드·그래프는 남는다).
    case noAttractivePoints
    /// 키워드만 없음 → 키워드 칩 줄만 사라진다.
    case noKeywords
    /// 읽기 상태 집계만 없음 → 읽기 상태 그래프만 사라진다.
    case noReadingStatus
    /// 매력포인트 하나만 있음 → 그 섹션만 남고 키워드·그래프가 사라진다.
    case onlyAttractivePoints
    /// 키워드 하나만 있음.
    case onlyKeywords
    /// 읽기 상태 그래프 하나만 있음.
    case onlyReadingStatus
    /// 독자 평가 셋 다 없음 → 감상평 영역 전체가 빈 상태로 대체된다(제목도 "독자들의 평가"로).
    case noReaderReview
    /// 피드 없음 → 피드 탭 빈 상태("아직 글이 없어요").
    case noFeed
    /// 피드 5개 → 첫 페이지 하나로 끝(hasNext 없음) — 목록이 화면보다 짧은 케이스.
    case feeds5
    /// 피드 15개 → 두 페이지(10+5) 페이지네이션.
    case feeds15
    /// 피드 45개 → 다섯 페이지 — 긴 목록 스크롤·연속 페이지네이션.
    case feeds45
    /// 거의 모든 값이 빈 신규 작품 — 썸네일·평점·플랫폼·평가·피드 없음.
    case minimal
    /// 작품 로드 실패 → NetworkErrorView(재시도).
    case loadFailure
    /// 피드 첫 페이지 로드 실패 → 피드 탭이 빈 상태 대신 실패 문구를 보여준다.
    case feedLoadFailure

    var id: Self { self }

    var title: String {
        switch self {
        case .full: "전체 데이터"
        case .noUserReview: "내 평가 없음"
        case .userReviewStatusOnly: "읽기 상태만 (보는 중)"
        case .userReviewWithRating: "별점 + 읽기 상태 (봤어요)"
        case .userReviewWithPeriod: "기간 + 읽기 상태 (하차)"
        case .userReviewWithRatingAndPeriod: "별점 + 기간 + 읽기 상태 (봤어요)"
        case .noAttractivePoints: "매력포인트 없음"
        case .noKeywords: "키워드 없음"
        case .noReadingStatus: "읽기 상태 없음"
        case .onlyAttractivePoints: "매력포인트만 있음"
        case .onlyKeywords: "키워드만 있음"
        case .onlyReadingStatus: "읽기 상태만 있음"
        case .noReaderReview: "독자 평가 전부 없음"
        case .noFeed: "피드 없음"
        case .feeds5: "피드 5개 (1페이지)"
        case .feeds15: "피드 15개 (2페이지)"
        case .feeds45: "피드 45개 (5페이지)"
        case .minimal: "최소 데이터(신규 작품)"
        case .loadFailure: "작품 로드 실패"
        case .feedLoadFailure: "피드 로드 실패"
        }
    }

    /// 버튼 목록의 묶음 — 무엇을 확인하는 시나리오인지 한눈에 보이게 한다.
    var group: String {
        switch self {
        case .full: "기본"
        case .noUserReview: "내 평가 — 없음"
        case .userReviewStatusOnly, .userReviewWithRating,
             .userReviewWithPeriod, .userReviewWithRatingAndPeriod: "내 평가 — 항목 조합"
        case .noAttractivePoints, .noKeywords, .noReadingStatus: "독자 평가 — 하나만 없음"
        case .onlyAttractivePoints, .onlyKeywords, .onlyReadingStatus: "독자 평가 — 하나만 있음"
        case .noReaderReview: "독자 평가 — 전부 없음"
        case .noFeed, .feeds5, .feeds15, .feeds45: "피드"
        case .minimal: "극단"
        case .loadFailure, .feedLoadFailure: "실패"
        }
    }

    /// 내 평가에서 채울 선택 항목. **nil이면 평가 자체가 없다**(→ 상태바 대신 셀렉터).
    /// 빈 집합은 "평가는 있고 읽기 상태만 있음"으로, nil과 의미가 다르다.
    var userReviewParts: Set<UserReviewPart>? {
        switch self {
        case .noUserReview, .minimal: nil
        case .userReviewStatusOnly: []
        case .userReviewWithRating: [.rating]
        case .userReviewWithPeriod: [.period]
        default: Set(UserReviewPart.allCases)
        }
    }

    /// 내 평가의 읽기 상태. 조합 시나리오마다 다른 값을 줘 **세 상태(보는 중·봤어요·하차)를 모두** 볼 수 있게 한다.
    var userReadingStatus: ReadingStatus {
        switch self {
        case .userReviewWithRating, .userReviewWithRatingAndPeriod: .watched
        case .userReviewWithPeriod: .quit
        default: .watching
        }
    }

    /// 독자 평가 중 **값을 채울 부분**. 세 축은 각각 독립이라 하나만 비면 그 섹션만 사라지고,
    /// 셋이 다 비어야 감상평 영역 전체가 빈 상태가 된다(정보 탭의 조건부 표시 규칙).
    /// 축별 Bool 프로퍼티를 따로 두지 않고 집합 하나로 표현한다 — 조건이 늘어도 여기 한 곳만 고치면 된다.
    var readerReviewParts: Set<ReaderReviewPart> {
        switch self {
        case .noAttractivePoints: [.keywords, .readingStatus]
        case .noKeywords: [.attractivePoints, .readingStatus]
        case .noReadingStatus: [.attractivePoints, .keywords]
        case .onlyAttractivePoints: [.attractivePoints]
        case .onlyKeywords: [.keywords]
        case .onlyReadingStatus: [.readingStatus]
        case .noReaderReview, .minimal: []
        default: Set(ReaderReviewPart.allCases)
        }
    }

    /// 피드 총 개수 — 0이면 피드 탭 빈 상태, 페이지 크기(10) 기준으로 페이지 수가 갈린다.
    var feedCount: Int {
        switch self {
        case .noFeed, .minimal, .feedLoadFailure: 0
        case .feeds5: 5
        case .feeds45: 45
        default: 15  // feeds15 포함 — 기본(전체 데이터)도 두 페이지 페이지네이션을 유지한다.
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

    /// Mock은 어떤 ID를 넣어도 같은 데이터를 돌려주므로 고정값을 쓴다(실서버만 입력받는다).
    private let mockNovelID = NovelID(1)

    @State private var dataSource: DataSource = .mock
    @State private var isDetailPresented = false
    /// 열 때마다 증가. detailView의 .id에 물려 매 진입마다 새 ViewModel이 만들어지게 한다.
    @State private var detailOpenCount = 0
    /// 마지막으로 누른 시나리오 버튼 — Mock 진입 시 주입할 데이터 조건.
    @State private var scenario: DemoScenario = .full
    /// 실서버로 조회할 작품 ID 입력값.
    @State private var novelIDText = "1"
    /// 진입 시점에 확정된 작품 ID — 화면이 떠 있는 동안 입력값을 바꿔도 흔들리지 않게 캡처해 둔다.
    @State private var liveNovelID = NovelID(1)

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                switch dataSource {
                case .mock:
                    // 시나리오 버튼이 곧 진입 버튼 — 어떤 데이터 조건으로 여는지가 버튼에 드러난다.
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(scenarioGroups, id: \.name) { group in
                                VStack(spacing: 8) {
                                    Text(group.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    ForEach(group.scenarios) { scenario in
                                        scenarioButton(scenario)
                                    }
                                }
                            }
                        }
                    }
                case .live:
                    liveControls
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("WSS Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isDetailPresented) {
                detailView
                    .id(detailOpenCount)
            }
            // 실서버 키워드 매핑은 파일 캐시(keywords.json)만 읽는다 — 실제 앱은 App(DI)이
            // 시작 시 syncKeywords()로 채우지만 Demo엔 그 계층이 없어, 토글 시 여기서 채운다.
            // 안 채우면 캐시 없는 시뮬레이터에서 fetchKeywords()가 실패해 키워드가 통째로 빈다.
            .task(id: dataSource) {
                guard dataSource == .live else { return }
                await makeLiveKeywordRepository(client: makeLiveClient()).syncKeywords()
            }
        }
    }

    /// 실서버는 조회할 작품 ID를 직접 입력받는다 — Mock과 달리 ID마다 데이터가 다르기 때문.
    private var liveControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text("작품 ID")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("예: 1", text: $novelIDText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
            Button("작품 상세 화면 열기") {
                open(.full)
            }
            .buttonStyle(.borderedProminent)
            // 빈 값·0·문자가 들어오면 열지 않는다(서버에 의미 없는 요청을 보내지 않게).
            .disabled(enteredNovelID == nil)
        }
    }

    /// 입력값 → 작품 ID. 양의 정수가 아니면 nil.
    private var enteredNovelID: NovelID? {
        guard let value = Int(novelIDText), value > 0 else { return nil }
        return NovelID(value)
    }

    /// 선언 순서를 유지한 채 group으로 묶는다(Dictionary(grouping:)은 순서가 흐트러진다).
    private var scenarioGroups: [(name: String, scenarios: [DemoScenario])] {
        DemoScenario.allCases.reduce(into: []) { groups, scenario in
            if groups.last?.name == scenario.group {
                groups[groups.count - 1].scenarios.append(scenario)
            } else {
                groups.append((name: scenario.group, scenarios: [scenario]))
            }
        }
    }

    /// 기본 조건(전체 데이터)만 채운 버튼으로 강조하고, 예외 조건은 테두리 스타일로 둔다.
    @ViewBuilder
    private func scenarioButton(_ scenario: DemoScenario) -> some View {
        let label = Text(scenario.title).frame(maxWidth: .infinity)
        if scenario == .full {
            Button { open(scenario) } label: { label }
                .buttonStyle(.borderedProminent)
        } else {
            Button { open(scenario) } label: { label }
                .buttonStyle(.bordered)
        }
    }

    private func open(_ scenario: DemoScenario) {
        self.scenario = scenario
        // 진입 시점의 입력값을 확정한다 — 화면이 떠 있는 동안 텍스트를 바꿔도 조회 대상은 안 바뀐다.
        if let id = enteredNovelID { liveNovelID = id }
        detailOpenCount += 1
        isDetailPresented = true
    }

    @ViewBuilder
    private var detailView: some View {
        switch dataSource {
        case .mock:
            // 삭제 UseCase가 기록하고 로드 UseCase가 읽는 공유 상태 — 삭제 → 재로드에서
            // 평가 없음(셀렉터) 화면으로 바뀌는 흐름을 서버 없이 시연한다. .id로 진입마다 초기화.
            let reviewDeletion = DemoReviewDeletion()
            NovelDetailFactory.makeView(
                novelID: mockNovelID,
                loadNovelUseCase: DemoLoadNovelUseCase(scenario: scenario, reviewDeletion: reviewDeletion),
                novelInterestUseCase: DemoNovelInterestUseCase(),
                loadNovelFeedsUseCase: DemoLoadNovelFeedsUseCase(scenario: scenario),
                feedLikeUseCase: DemoFeedLikeUseCase(),
                deleteFeedUseCase: DemoDeleteFeedUseCase(),
                deleteNovelReviewUseCase: DemoDeleteNovelReviewUseCase(reviewDeletion: reviewDeletion),
                reportSpoilerFeedUseCase: DemoReportSpoilerFeedUseCase(),
                reportImproperFeedUseCase: DemoReportImproperFeedUseCase(),
                logger: consoleLogger,
                onReviewTapped: handleReviewTapped,
                onCreateFeedTapped: handleCreateFeedTapped,
                onFeedTapped: handleFeedTapped,
                onUserProfileTapped: handleUserProfileTapped,
                onEditFeedTapped: handleEditFeedTapped
            )
        case .live:
            makeLiveView()
        }
    }

    // MARK: - 실서버 조립

    // NetworkingConfig.baseURL로 호출하고, DemoSessionTokenStore가 TEST_API_KEY를
    // accessToken으로 제공해 .requireToken 엔드포인트를 인증한다.
    @MainActor
    private func makeLiveClient() -> NetworkingClient {
        NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )
    }

    @MainActor
    private func makeLiveKeywordRepository(client: NetworkingClient) -> KeywordRepository {
        KeywordDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "BaseData", underlying: consoleLogger)
        )
    }

    @MainActor
    private func makeLiveView() -> some View {
        let client = makeLiveClient()
        let novelRepository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: UserDefaultsStorage(),
            logger: DataLogger(moduleName: "NovelData", underlying: consoleLogger)
        )
        let keywordRepository = makeLiveKeywordRepository(client: client)
        let feedRepository = FeedDataFactory.makeFeedRepository(
            client: client,
            logger: DataLogger(moduleName: "FeedData", underlying: consoleLogger)
        )
        let novelReviewRepository = NovelReviewDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "NovelReviewData", underlying: consoleLogger)
        )
        let socialRepository = SocialDataFactory.makeSocialRepository(
            client: client,
            underlying: consoleLogger
        )
        return NovelDetailFactory.makeView(
            novelID: liveNovelID,
            loadNovelUseCase: DefaultLoadNovelUseCase(
                novelRepository: novelRepository,
                keywordRepository: keywordRepository
            ),
            novelInterestUseCase: DefaultNovelInterestUseCase(novelRepository: novelRepository),
            loadNovelFeedsUseCase: DefaultLoadNovelFeedsUseCase(feedRepository: feedRepository),
            feedLikeUseCase: DefaultLikeUseCase(feedRepository: feedRepository),
            deleteFeedUseCase: DefaultDeleteFeedUseCase(repository: feedRepository),
            deleteNovelReviewUseCase: DefaultDeleteNovelReviewUseCase(repository: novelReviewRepository),
            reportSpoilerFeedUseCase: DefaultReportSpoilerFeedUseCase(repository: socialRepository),
            reportImproperFeedUseCase: DefaultReportImproperFeedUseCase(repository: socialRepository),
            logger: consoleLogger,
            onReviewTapped: handleReviewTapped,
            onCreateFeedTapped: handleCreateFeedTapped,
            onFeedTapped: handleFeedTapped,
            onUserProfileTapped: handleUserProfileTapped,
            onEditFeedTapped: handleEditFeedTapped
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

    /// 피드 상세 진입 콜백. 실제 앱은 App 조정 계층이 피드 상세로 전환한다 — Demo는 로그만.
    private func handleFeedTapped(_ feedID: FeedID) {
        consoleLogger.info("피드 상세 진입 요청: \(feedID)")
    }

    /// 유저 프로필 진입 콜백(내 글이면 호출 안 됨). 실제 앱은 App 조정 계층이 프로필로 전환한다 — Demo는 로그만.
    private func handleUserProfileTapped(_ userID: UserID) {
        consoleLogger.info("유저 프로필 진입 요청: \(userID)")
    }

    /// 피드 수정 진입 콜백(내 글 드롭다운의 "수정하기"). 실제 앱은 CreateFeed 수정 모드로 전환한다 — Demo는 로그만.
    private func handleEditFeedTapped(_ feed: TotalFeed) {
        consoleLogger.info("피드 수정 진입 요청: \(feed.feedId)")
    }
}

// MARK: - Demo UseCases (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요).

/// Mock 평가 삭제 상태 — 삭제 UseCase가 기록하고 로드 UseCase가 읽는다.
/// 화면 진입 단위(detailView의 .id)로 새로 만들어져 재진입 시 시나리오 원본으로 돌아간다.
private final class DemoReviewDeletion {
    var isDeleted = false
}

private struct DemoLoadNovelUseCase: LoadNovelUseCase {

    let scenario: DemoScenario
    let reviewDeletion: DemoReviewDeletion

    func execute(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        try? await Task.sleep(nanoseconds: 500_000_000)
        if scenario == .loadFailure {
            throw .serverUnavailable
        }
        let isMinimal = scenario == .minimal
        let parts = scenario.readerReviewParts
        return NovelInformation(
            novel: Novel(
                id: id,
                // 최소 데이터는 표지 없음(플레이스홀더 확인용).
                thumbnailImage: isMinimal
                    ? nil
                    : URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
                title: isMinimal ? "이제 막 등록된 신규 작품" : "당신의 이해를 돕기 위하여",
                authors: isMinimal ? ["작가 미상"] : ["이보라"],
                genres: [.romanceFantasy, .romance],
                interestCount: isMinimal ? 0 : 128,
                // 평점 없음 = rating 0 / ratingCount 0 (Novel.rating은 non-optional).
                rating: isMinimal ? 0 : 4.4,
                ratingCount: isMinimal ? 0 : 52,
                isInterested: false
            ),
            feedCount: scenario.feedCount,
            genres: [.romanceFantasy, .romance],
            publicationStatus: isMinimal ? .onGoing : .completed,
            // nil이면 평가 자체가 없다 → 상태바 대신 셀렉터. 빈 집합이면 읽기 상태만 있는 평가다.
            // 삭제된 뒤의 재로드면 시나리오와 무관하게 평가 없음 — 삭제 → 셀렉터 전환 흐름 시연.
            userReview: reviewDeletion.isDeleted ? nil : scenario.userReviewParts.map { parts in
                let status = scenario.userReadingStatus
                return UserNovelReview(
                    readingStatus: status,
                    rating: parts.contains(.rating) ? (try? Rating(4.0)) : nil,
                    attractivePoint: [.character, .vibe],
                    // 시작·종료를 다 넣고 도메인 `normalized(for:)`에 맡긴다 — 상태별 날짜 규칙
                    // (보는 중=시작만 / 봤어요=시작+종료 / 하차=종료만)을 Demo가 흉내내지 않게 한다.
                    period: parts.contains(.period)
                        ? (try? ReadingPeriod(
                            start: Date(timeIntervalSinceNow: -86_400 * 300),
                            end: Date(timeIntervalSinceNow: -86_400 * 30)
                        ))?.normalized(for: status)
                        : nil,
                    keywords: []
                )
            },
            description: isMinimal
                ? "아직 소개가 짧은 작품입니다."
                : "왕실에는 막대한 빚이 있었고, 그들은 빚을 갚기 위해 왕녀인 바이올렛을 막대한 돈을 지녔지만 공작의 사생아인 윈터에게 시집보낸다. 계약 결혼으로 시작된 두 사람의 이야기. 라고 할 뻔 \n\n\n 과연 어디까지 늘어나는지 봅시다 한 번",
            // 플랫폼이 비면 "작품 보러가기" 섹션 자체가 사라진다.
            platforms: isMinimal ? [] : [
                URL(string: "https://novel.naver.com").map {
                    NovelPlatform(name: "네이버시리즈", image: nil, url: $0)
                },
                URL(string: "https://page.kakao.com").map {
                    NovelPlatform(name: "카카오페이지", image: nil, url: $0)
                }
            ].compactMap { $0 },
            // 아래 셋은 각각 독립으로 숨겨지고, 전부 비면 감상평 영역이 빈 상태로 대체된다
            // (제목도 "독자들의 평가"로 바뀜).
            attractivePoints: parts.contains(.attractivePoints)
                ? [.character, .relationship, .writingSkill]
                : [],
            keywords: parts.contains(.keywords) ? [
                NovelKeyword(keyword: Keyword(id: KeywordID(1), name: "피폐"), count: 7),
                NovelKeyword(keyword: Keyword(id: KeywordID(2), name: "정치물"), count: 5),
                NovelKeyword(keyword: Keyword(id: KeywordID(3), name: "궁중암투"), count: 3),
                NovelKeyword(keyword: Keyword(id: KeywordID(4), name: "빙의"), count: 2),
                NovelKeyword(keyword: Keyword(id: KeywordID(5), name: "후회"), count: 2)
            ] : [],
            // 그래프는 count가 전부 0이면 사라진다 — 키를 지우는 것과 0으로 두는 것이 같다(dominantReadStatus가 nil).
            readingStatusCount: parts.contains(.readingStatus)
                ? [.watching: 130, .watched: 10, .quit: 100]
                : [:]
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

/// Mock 평가 삭제 — 항상 성공하고, 삭제 사실만 공유 상태에 남긴다(재로드가 읽는다).
private struct DemoDeleteNovelReviewUseCase: DeleteNovelReviewUseCase {

    let reviewDeletion: DemoReviewDeletion

    func execute(novelID: NovelID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
        reviewDeletion.isDeleted = true
    }
}

/// Mock 좋아요 — 항상 성공. 낙관 반영·롤백은 VM 소관이라 여기선 지연만 흉내낸다.
private struct DemoFeedLikeUseCase: FeedLikeUseCase {
    func like(feedID: FeedID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }

    func unlike(feedID: FeedID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

/// Mock 피드 삭제 — 항상 성공. 목록 제거는 VM이 수행하므로 상태를 남길 필요가 없다.
private struct DemoDeleteFeedUseCase: DeleteFeedUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

/// Mock 신고 — 항상 성공(접수 완료 알럿 전환 확인용).
private struct DemoReportSpoilerFeedUseCase: ReportSpoilerFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

private struct DemoReportImproperFeedUseCase: ReportImproperFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

private struct DemoLoadNovelFeedsUseCase: LoadNovelFeedsUseCase {

    let scenario: DemoScenario

    func execute(novelID: NovelID,
                 lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        try? await Task.sleep(nanoseconds: 500_000_000)
        if scenario == .feedLoadFailure {
            throw .networkUnavailable
        }
        // 커서 0 = 첫 페이지, 이후 커서 = 마지막 피드 ID(피드 번호와 동일).
        // 페이지 크기 10으로 시나리오의 feedCount까지 잘라 낸다 — 5개(1페이지)·15개(2페이지)·45개(5페이지).
        let start = lastFeedID.value == 0 ? 1 : lastFeedID.value + 1
        guard start <= scenario.feedCount else {
            return Paginated(items: [], hasNext: false)
        }
        let end = min(start + 9, scenario.feedCount)
        return Paginated(items: (start...end).map(makeFeed), hasNext: end < scenario.feedCount)
    }

    private func makeFeed(_ number: Int) -> TotalFeed {
        TotalFeed(
            feedId: FeedID(number),
            createdDate: "\(number)시간 전",
            content: "데모 피드 \(number) — 이 작품 정말 소소하게 재밌네요.",
            author: Author(userId: UserID(number), nickname: "소소한 독자 \(number)", profileImage: nil),
            likeCount: number,
            isLiked: false,
            commentCount: 0,
            isSpoiler: false,
            isModified: false,
            isPublic: true,
            // 3의 배수 피드는 내 글 — threedots 드롭다운(수정/삭제 vs 신고)·프로필 이동 차단 분기 시연용.
            isMyFeed: number.isMultiple(of: 3),
            imageCount: 0
        )
    }
}
