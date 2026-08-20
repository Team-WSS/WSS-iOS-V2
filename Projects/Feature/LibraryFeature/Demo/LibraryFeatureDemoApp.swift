//
//  LibraryFeatureDemoApp.swift
//  LibraryFeatureDemo
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import LibraryFeature
import BaseDomain
import NovelDomain
import BaseData
import NovelData
import Logger
import Networking
import DesignSystem

@main
struct LibraryFeatureDemoApp: App {
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

/// 타유저 서재 Mock 시나리오 — **버튼 하나 = 데이터 조건 하나**(NovelDetailFeature Demo 규약).
/// 실서버 모드에선 무시되고 실제 응답을 그린다.
private enum DemoUserLibraryScenario: String, CaseIterable, Identifiable {
    case filled = "정상"
    case empty = "빈 서재"
    case failure = "실패"
    /// 첫 페이지는 성공하고 **더보기만** 실패 — root의 "다음 요청 실패" 주입은 push된 이 화면에서 누를 수
    /// 없어서(첫 요청이 먼저 소비한다) 더보기 실패 경로를 만들려면 전용 시나리오가 필요하다.
    case loadMoreFailure = "더보기 실패"
    /// 인증 만료 — 로그인 라우팅 콜백이 만료마다 정확히 1회씩 발화하는지 보는 축.
    /// (신호를 소진하는 구조라 재로드하면 다시 발화해야 한다. 인증 만료는 실패 뷰를 세우지 않으므로
    ///  카운트·정렬 행이 살아 있다 → 2회차 발화는 정렬 변경으로 확인한다.)
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

    @State private var dataSource: DataSource = .mock
    /// 실서버 서재 응답의 키워드 이름을 `Keyword`로 복원할 수 있도록, 목록을 만들기 전에 캐시를 채운다.
    @State private var isLiveKeywordCacheReady = false
    /// push된 타유저 서재 — nil이면 닫힌 상태.
    @State private var presentedUserLibrary: DemoUserLibraryScenario?
    /// push된 더미 화면 — **재진입 갱신을 재현하는 유일한 경로**(아래 `refreshEntryRow` 주석).
    @State private var isAwayScreenPresented = false
    /// "작품 추가" 누른 횟수. 값 자체는 안 쓰고 **라벨을 다시 그리게 하는 트리거**로만 쓴다 —
    /// 실제 개수는 `DemoLibraryNovels.totalCount`(SwiftUI가 관찰하지 않는 static이라 이 신호가 필요하다).
    @State private var addedNovelCount = 0
    /// 소스 전환 시 화면 정체성을 갈아 새 ViewModel(깨끗한 로드)을 강제한다.
    private var libraryViewID: String { dataSource.rawValue }

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    /// 실서버 타유저 서재 조회 대상 — 내 서재(10041)와 다른 사용자여야 "타유저" 경로가 실제로 검증된다.
    private let liveOtherUserID = 10032

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                userLibraryEntryRow
                refreshEntryRow

                libraryView
                    .id(libraryViewID)
            }
            .navigationDestination(item: $presentedUserLibrary) { scenario in
                userLibraryView(scenario)
            }
            .navigationDestination(isPresented: $isAwayScreenPresented) {
                DemoAwayScreen()
            }
            .task(id: dataSource) {
                guard dataSource == .live else {
                    isLiveKeywordCacheReady = false
                    return
                }

                let client = makeLiveClient()
                // ⚠️ `syncKeywords()`는 실패를 안으로 삼키므로 이 플래그는 "동기화를 **시도**했다"까지만 뜻한다 —
                // 네트워크가 죽어 캐시가 비어도 true가 된다(그땐 키워드 칩만 조용히 빈다). Demo 편의 가드라 이 정도로 둔다.
                await makeLiveKeywordRepository(client: client).syncKeywords()
                isLiveKeywordCacheReady = true
            }
        }
    }

    /// 타유저 서재 진입 — 실제 흐름과 같이 **push**로 띄워 뒤로가기·스와이프백까지 함께 검증한다.
    private var userLibraryEntryRow: some View {
        HStack(spacing: 8) {
            Text("타유저 서재")
                .font(.caption)
            if dataSource == .mock {
                ForEach(DemoUserLibraryScenario.allCases) { scenario in
                    Button(scenario.rawValue) { presentedUserLibrary = scenario }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            } else {
                Button("ID \(liveOtherUserID)") { presentedUserLibrary = .filled }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    /// 재진입 갱신(`.refresh`) 검증용 행.
    ///
    /// ⚠️ **내 서재는 인라인이라 "나갔다 오기"가 없으면 갱신 경로가 한 번도 안 돈다** — 실앱에선 탭 전환·
    /// 작품 상세 pop이 그 역할을 하지만 Demo엔 그게 없었다. 여기서 push했다 돌아오면 ViewModel은 살아 있고
    /// `onAppear`만 다시 발화해 실앱의 탭 복귀와 같은 조건이 된다(`.id()`를 건드리면 VM이 새로 생겨 무의미).
    ///
    /// "작품 추가"는 **delta 경로(2차 요청)** 재현용 — 총 개수가 안 변하면 delta가 늘 0이라 2차가 안 돈다.
    private var refreshEntryRow: some View {
        HStack(spacing: 8) {
            Text("갱신 검증")
                .font(.caption)
            Button("나갔다 오기") { isAwayScreenPresented = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            Button("작품 추가") {
                DemoLibraryNovels.addNovel()
                addedNovelCount += 1
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Button("다음 요청 실패") { DemoLibraryNovels.failNextRequest() }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
            Text("서버 총 \(DemoLibraryNovels.totalCount)개")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func userLibraryView(_ scenario: DemoUserLibraryScenario) -> some View {
        switch dataSource {
        case .mock:
            LibraryFactory.makeUserLibraryView(
                userID: UserID(1003),
                loadUserLibraryUseCase: DemoLoadUserLibraryUseCase(scenario: scenario),
                logger: consoleLogger,
                onNovelSelected: { consoleLogger.info("작품 상세 진입 요청: \($0)") },
                onAuthenticationRequired: handleAuthenticationRequired
            )
        case .live:
            // 내 서재와 같은 가드 — 키워드 캐시가 비어 있으면 목록의 키워드 칩이
            // 에러 없이 통째로 빈 채로 그려져(UseCase가 try? + ?? []로 폴백) 오진하기 쉽다.
            if isLiveKeywordCacheReady {
                makeLiveUserLibraryView()
            } else {
                ProgressView("키워드 목록 불러오는 중")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private var libraryView: some View {
        switch dataSource {
        case .mock:
            LibraryFactory.makeMyLibraryView(
                loadMyLibraryUseCase: DemoLoadMyLibraryUseCase(),
                loadMyLibraryKeywordsUseCase: DemoLoadMyLibraryKeywordsUseCase(),
                logger: consoleLogger,
                onNovelSelected: { consoleLogger.info("작품 상세 진입 요청: \($0)") },
                onSearchTapped: { consoleLogger.info("웹소설 찾기(검색) 진입 요청") },
                onRegisterTapped: { consoleLogger.info("작품 등록 진입 요청") },
                onNotificationTapped: { consoleLogger.info("알림 관리 진입 요청") },
                onAuthenticationRequired: handleAuthenticationRequired
            )
        case .live:
            if isLiveKeywordCacheReady {
                makeLiveView()
            } else {
                ProgressView("키워드 목록 불러오는 중")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - 실서버 조립

    // NetworkingConfig.baseURL로 호출하고, DemoSessionTokenStore가 TEST_API_KEY를
    // accessToken으로 제공해 .requireToken 엔드포인트를 인증한다.
    // 내 서재 조회는 저장된 userID를 쓰므로 Demo가 직접 세팅한다(NovelData Demo와 동일 값).
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

    /// 실서버 Repository 조립 — 내 서재·타유저 서재가 같은 배관을 쓴다.
    @MainActor
    private func makeLiveRepositories() -> (novel: NovelRepository, keyword: KeywordRepository) {
        let client = makeLiveClient()
        let userDefaults = UserDefaultsStorage()
        userDefaults.set(.userID, 10041)
        let repository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: userDefaults,
            logger: DataLogger(moduleName: "NovelData", underlying: consoleLogger)
        )
        return (repository, makeLiveKeywordRepository(client: client))
    }

    @MainActor
    private func makeLiveUserLibraryView() -> some View {
        let repositories = makeLiveRepositories()
        return LibraryFactory.makeUserLibraryView(
            userID: UserID(liveOtherUserID),
            loadUserLibraryUseCase: DefaultLoadUserLibraryUseCase(
                novelRepository: repositories.novel,
                keywordRepository: repositories.keyword
            ),
            logger: consoleLogger,
            onNovelSelected: { consoleLogger.info("작품 상세 진입 요청: \($0)") },
            onAuthenticationRequired: handleAuthenticationRequired
        )
    }

    @MainActor
    private func makeLiveView() -> some View {
        let repositories = makeLiveRepositories()
        let repository = repositories.novel
        let keywordRepository = repositories.keyword
        return LibraryFactory.makeMyLibraryView(
            loadMyLibraryUseCase: DefaultLoadMyLibraryUseCase(
                novelRepository: repository,
                keywordRepository: keywordRepository
            ),
            loadMyLibraryKeywordsUseCase: DefaultLoadMyLibraryKeywordsUseCase(novelRepository: repository),
            logger: consoleLogger,
            onNovelSelected: { consoleLogger.info("작품 상세 진입 요청: \($0)") },
            onSearchTapped: { consoleLogger.info("웹소설 찾기(검색) 진입 요청") },
            onRegisterTapped: { consoleLogger.info("작품 등록 진입 요청") },
            onNotificationTapped: { consoleLogger.info("알림 관리 진입 요청") },
            onAuthenticationRequired: handleAuthenticationRequired
        )
    }

    /// 인증 만료 콜백. 실제 앱은 App 조정 계층이 로그인 화면으로 전환한다 — Demo는 로그만.
    private func handleAuthenticationRequired() {
        consoleLogger.info("인증 만료 → 로그인 진입 요청")
    }
}

/// 재진입을 만들기 위한 빈 화면. 내용은 없어도 되고, **떠났다 돌아오는 것 자체**가 목적이다.
private struct DemoAwayScreen: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("다른 화면")
                .font(.title2)
            Text("뒤로가기로 돌아가면 서재가 갱신된다.\n(요청 로그로 1차·2차를 확인)")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Demo UseCases (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요). 총 25개라 기본 페이지 크기 20이면 2페이지.

private struct DemoLoadMyLibraryUseCase: LoadMyLibraryUseCase {

    /// ⚠️ 요청을 **찍어야** 갱신이 2단계로 도는지(1차 size=보던 개수 → 2차 size=delta) 확인할 수 있다 —
    /// 화면만 봐서는 요청이 1번인지 2번인지 구분되지 않는다.
    func execute(
        filter: MyLibraryFilter,
        cursor: String?,
        size: Int
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        print("[Demo] 내 서재 요청 — cursor: \(cursor ?? "nil"), size: \(size)")
        try? await Task.sleep(nanoseconds: 500_000_000)

        if await DemoLibraryNovels.consumeInjectedFailure() {
            print("[Demo] 내 서재 응답 — 주입된 실패(networkUnavailable)")
            throw .networkUnavailable
        }

        let result = await DemoLibraryNovels.page(cursor: cursor, size: size, sortType: filter.sortType)
        print("[Demo] 내 서재 응답 — \(result.0.items.count)건, 전체 \(result.1), 다음커서 \(result.0.nextCursor ?? "없음")")
        return result
    }
}

/// 타유저 서재 Mock — 시나리오(정상·빈 서재·실패)별로 다른 응답을 낸다.
/// 목록 데이터는 내 서재 Mock과 공유한다(같은 셀을 그리므로 값 조합 축이 같아야 비교가 된다).
private struct DemoLoadUserLibraryUseCase: LoadUserLibraryUseCase {

    let scenario: DemoUserLibraryScenario

    func execute(
        id: UserID,
        filter: LibraryFilter,
        cursor: String?
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        try? await Task.sleep(nanoseconds: 500_000_000)

        switch scenario {
        case .filled:
            return await DemoLibraryNovels.page(cursor: cursor, sortType: filter.sortType)
        case .loadMoreFailure:
            guard cursor == nil else { throw .networkUnavailable }
            return await DemoLibraryNovels.page(cursor: cursor, sortType: filter.sortType)
        case .empty:
            return (CursorPaginated(items: [], hasNext: false, nextCursor: nil), 0)
        case .failure:
            throw .networkUnavailable
        case .authExpired:
            throw .authenticationRequired
        }
    }
}

private enum DemoLibraryNovels {

    /// 총 25개. 커서는 다음 시작 인덱스를 문자열로 왕복한다.
    ///
    /// ⚠️ `size`를 **실제로 반영해야** 내 서재의 재진입 갱신(보고 있던 개수만큼 한 번에 다시 받기)을
    /// Demo에서 확인할 수 있다 — 20으로 고정해두면 그 경로가 늘 한 페이지처럼 보여 검증이 안 된다.
    ///
    /// `sortType`은 **순서가 실제로 바뀌는지 눈으로 보려고만** 쓴다(서버 정렬 규칙을 흉내내지 않는다) —
    /// 정렬을 바꿔도 목록이 그대로면 재로드가 도는지 알 수 없어서다.
    /// Demo에서 "작품 추가"로 늘어난 개수. **갱신의 delta 경로(2차 요청)를 재현하려면 총 개수가 변해야 한다** —
    /// 고정 25개로는 delta가 항상 0이라 2차 요청이 영영 안 돈다.
    @MainActor private(set) static var addedCount = 0

    /// 자리를 비운 사이 서버에 작품이 등록된 상황을 흉내낸다. 등록 최신순이라 **목록 맨 앞**에 붙는다.
    @MainActor static func addNovel() { addedCount += 1 }

    /// **1회성** 실패 주입 — 갱신 실패(전면 실패 뷰)와 그 뒤 복구 경로를 보려면 실패가 한 번만 나야 한다.
    /// 계속 실패하면 재시도가 무엇을 그리는지(로딩→목록)를 확인할 수 없다.
    ///
    /// ⚠️ **내 서재 전용이다.** 한때 타유저 서재 Mock도 이걸 소비하게 했다가 걷어냈다 — 주입해두고
    /// 타유저 서재에 들어가면 **그 화면 첫 요청이 먹어버려** 정작 보려던 내 서재 갱신 실패가 안 난다
    /// (순서 의존이라 "왜 실패가 안 나지"로 오진하기 쉽다). 타유저 서재는 `loadMoreFailure` 시나리오를 쓴다.
    @MainActor private static var shouldFailNextRequest = false

    @MainActor static func failNextRequest() { shouldFailNextRequest = true }

    @MainActor static func consumeInjectedFailure() -> Bool {
        defer { shouldFailNextRequest = false }
        return shouldFailNextRequest
    }

    @MainActor static var totalCount: Int { baseNovels.count + addedCount }

    @MainActor static func page(
        cursor: String?,
        size: Int = 20,
        sortType: LibrarySortType = .registeredNewest
    ) -> (CursorPaginated<LibraryNovel>, Int) {
        let sorted = Self.sorted(by: sortType)
        let start = cursor.flatMap(Int.init) ?? 0
        let end = min(start + size, sorted.count)
        guard start < end else {
            return (CursorPaginated(items: [], hasNext: false, nextCursor: nil), sorted.count)
        }

        let hasNext = end < sorted.count
        let page = CursorPaginated(
            items: Array(sorted[start..<end]),
            hasNext: hasNext,
            nextCursor: hasNext ? "\(end)" : nil
        )
        return (page, sorted.count)
    }

    /// 정렬마다 **눈에 보이게 다른 순서**를 낸다 — 두 정렬이 같은 결과면 재로드가 도는지 확인할 수 없어서다.
    @MainActor private static func sorted(by sortType: LibrarySortType) -> [LibraryNovel] {
        let all = currentNovels
        switch sortType {
        case .registeredNewest: return all
        case .registeredOldest: return all.reversed()
        case .title:            return all.sorted { $0.title < $1.title }
        case .readDate:         return all.sorted { $0.title > $1.title }
        case .ratingHighest:    return all.sorted { ($0.userReview?.rating?.value ?? 0) > ($1.userReview?.rating?.value ?? 0) }
        case .ratingLowest:     return all.sorted { ($0.userReview?.rating?.value ?? 0) < ($1.userReview?.rating?.value ?? 0) }
        }
    }

    /// 추가분 + 기본 25개. 추가분이 **앞**이라 등록 최신순에서 새 작품이 기존 목록을 밀어낸다 —
    /// 갱신이 delta를 보정하지 않으면 그만큼 뒤가 잘려 나가는 게 눈에 보인다.
    @MainActor private static var currentNovels: [LibraryNovel] {
        guard addedCount > 0 else { return baseNovels }
        return (1...addedCount).reversed().map(makeAddedNovel) + baseNovels
    }

    /// 추가된 작품은 **제목만으로 구분되게** 둔다(스냅샷에서 바로 확인하려고).
    private static func makeAddedNovel(_ number: Int) -> LibraryNovel {
        LibraryNovel(
            id: NovelID(1000 + number),
            title: "새로 등록한 작품 \(number)",
            thumbnailImage: nil,
            rating: 4.2,
            isInterested: false,
            userReview: nil,
            writtenFeeds: []
        )
    }

    private static let demoKeywordNames = ["빙의", "후회", "궁중암투", "웹툰화"]

    /// 셀이 값 조합에 따라 어떻게 보이는지 한 화면에서 확인하려고 축을 서로 다른 주기로 돌린다 —
    /// 제목 줄 수(2) · 표지 유무(5) · 읽기 상태(3) · 별점 유무(4) · 기간 유무(4) · 매력포인트 수(4) · 키워드 수(5).
    /// 그리드 행이 어긋나거나 특정 조합이 깨지면 여기서 바로 드러난다.
    private static let baseNovels: [LibraryNovel] = (1...25).map { index in
        let isLongTitle = index.isMultiple(of: 2)
        let hasRating = index % 4 != 0
        let hasPeriod = index % 4 != 1

        let status = ReadingStatus.allCases[index % ReadingStatus.allCases.count]

        // 기간은 상태별로 채워지는 날짜가 다르다(보는 중=시작, 봤어요=시작+종료, 하차=종료).
        // 그 규칙은 도메인이 강제하므로 Mock이 흉내내지 말고 normalized(for:)를 태운다.
        let rawStart = Date(timeIntervalSince1970: 1_700_000_000 + Double(index) * 86_400 * 10)
        let period = hasPeriod
            ? (try? ReadingPeriod(start: rawStart, end: rawStart.addingTimeInterval(86_400 * 60)))?
                .normalized(for: status)
            : nil

        let review: UserNovelReview? = index % 5 == 0
            ? nil
            : UserNovelReview(
                readingStatus: status,
                rating: hasRating ? try? Rating(Double(index % 9 + 1) * 0.5) : nil,
                attractivePoint: Array(AttractivePoint.allCases.prefix(index % 4)),
                period: period,
                keywords: (0..<(index % 5)).map {
                    Keyword(id: KeywordID($0 + 1), name: demoKeywordNames[$0])
                }
            )

        return LibraryNovel(
            id: NovelID(index),
            // 그리드 2줄·리스트 1줄 말줄임을 모두 확인할 수 있는 긴 제목 케이스.
            title: isLongTitle
                ? "나는 분명 조용히 살고 싶었을 뿐인데 어쩌다 보니 황태자비가 되어 버렸다 \(index)"
                : "데모 작품 \(index)",
            // 표지 비율(108:160)의 실제 이미지. 5번째마다 nil로 둬 WSS 빈 표지 폴백도 함께 확인한다.
            thumbnailImage: index.isMultiple(of: 5)
                ? nil
                : URL(string: "https://picsum.photos/seed/wss\(index)/216/320"),
            rating: 4.2,
            isInterested: index.isMultiple(of: 3),
            userReview: review,
            writtenFeeds: []
        )
    }
}

private struct DemoLoadMyLibraryKeywordsUseCase: LoadMyLibraryKeywordsUseCase {
    func execute() async throws(RepositoryError) -> [Keyword] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return [
            Keyword(id: KeywordID(1), name: "빙의"),
            Keyword(id: KeywordID(2), name: "후회"),
            Keyword(id: KeywordID(3), name: "궁중암투"),
            Keyword(id: KeywordID(4), name: "웹툰화")
        ]
    }
}
