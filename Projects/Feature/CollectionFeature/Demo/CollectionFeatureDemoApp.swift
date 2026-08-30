//
//  CollectionFeatureDemoApp.swift
//  CollectionFeatureDemo
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import KakaoSDKCommon

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

        // 컬렉션 상세 "공유하기"(카카오톡 공유 카드, #228)를 Demo 단독으로 확인하려면 앱 진입점 초기화가
        // 필요하다(`OnboardingFeatureDemoApp`과 동일 — App과 별개 프로세스라 App의 초기화를 못 물려받는다).
        KakaoSDK.initSDK(appKey: NetworkingConfig.kakaoAppKey)
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView()
        }
    }
}

// MARK: - Root: Mock ↔ 실서버 토글

// Demo가 App(DI+조정 계층) 역할을 대행해 UseCase를 조립하고 화면 전환까지 담당한다 — 모듈 안엔
// navigationDestination이 없다("화면 간 이동은 전부 App이 조립한다", 모듈 CLAUDE.md 참고).
private struct DemoRootView: View {
    private enum DataSource: String, CaseIterable, Identifiable {
        case mock = "Mock"
        case live = "실서버"
        var id: String { rawValue }
    }

    /// Demo가 대행하는 App Destination. 실제 App(MypageRootView 등)이 쓸 설계를 그대로 미리 검증한다 —
    /// `CollectionNovel`은 Hashable이 아니라(`CollectionFeatureFactory` 주석 참고) "작품 추가"/"서재에서
    /// 추가"의 초기 선택 목록은 path payload가 아니라 별도 스크래치 State로 채널링한다.
    private enum Destination: Hashable {
        case create
        case edit(CollectionID)
        case list(isEmpty: Bool)
        case detail(CollectionID)
        /// 진입 시점의 선택 스냅샷을 path payload로 직접 태운다 — 별도 `@State` 스크래치 변수에 먼저
        /// 써두고 그 값을 읽어 destination을 만드는 방식은 **레이스가 있다**(실측, 2026-08-28): 같은
        /// 액션 안에서 `scratchState = value; path.append(...)`처럼 `@State` 갱신과 push를 연달아
        /// 해도, `.navigationDestination(for:)`가 새 destination view를 만드는 시점에 그 `@State`
        /// 갱신이 아직 반영되지 않은 이전 값(빈 배열)을 읽어버려 "작품 추가"→"서재에서 추가"로 넘어갈
        /// 때 검색에서 고른 작품이 통째로 사라지는 버그로 실제 재현됐다. `CollectionNovel`이
        /// Hashable(#201)이라 이제 배열째로 payload에 넣을 수 있다.
        case searchNovel([CollectionNovel])
        case myLibrarySelect([CollectionNovel])
    }

    @State private var dataSource: DataSource = .mock
    @State private var path = NavigationPath()

    /// "작품 추가"/"서재에서 추가" 확정 결과를 생성/수정 화면(`CreateCollectionView`)에 돌려주는
    /// 1회성 nil→값 채널(`CollectionFeatureFactory.makeCreateCollectionView` 문서 참고). 생성·수정
    /// 모드가 동시에 열릴 일이 없어 하나로 공유한다. **이건 진입(entry) 파라미터가 아니라 확정
    /// (return) 값**이라 위 레이스 대상이 아니다 — 이미 mount된 `CreateCollectionView`가 `.onChange`로
    /// 값 변화를 관찰하는 구조라, "아직 mount 안 된 destination이 최신 `@State`를 못 읽는" 문제 자체가
    /// 성립하지 않는다.
    @State private var pendingNovelSelection: [CollectionNovel]?

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 24) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Button("컬렉션 생성 화면 열기") {
                    path.append(Destination.create)
                }
                .buttonStyle(.borderedProminent)

                Button("컬렉션 목록 화면 열기") {
                    path.append(Destination.list(isEmpty: false))
                }
                .buttonStyle(.bordered)

                // Mock 전용 — 실서버는 실제 계정 데이터를 그대로 조회하므로 빈 상태를 강제할 수 없다.
                // 두 탭(내 컬렉션/좋아요한 컬렉션) 모두 첫 페이지부터 빈 배열을 반환해, 세그먼트를
                // 오가며 두 탭의 빈 상태(CTA 유무 차이 포함)를 한 화면에서 확인할 수 있다.
                if dataSource == .mock {
                    Button("컬렉션 목록 (빈 상태) 열기") {
                        path.append(Destination.list(isEmpty: true))
                    }
                    .buttonStyle(.bordered)
                }

                // Mock 전용 — 컬렉션 목록에서 카드를 탭해도 상세로 갈 수 있지만(CollectionListView의
                // onCollectionSelected), 상세 화면 자체를 바로 확인하려면 목록을 거쳐야 하는 번거로움이
                // 있었다. DemoLoadCollectionDetailUseCase가 컬렉션 id의 홀짝/4배수로 이미 3가지 상태
                // (타인 컬렉션/내 컬렉션·공개/내 컬렉션·비공개)를 구분해 반환하므로, 그 id를 그대로
                // 바로가기로 노출한다. 실서버는 데모가 아는 실제 컬렉션 id가 없어 제외한다(목록 화면에서
                // 카드를 탭해 진입하는 경로만 유효).
                if dataSource == .mock {
                    Divider().padding(.vertical, 8)

                    Text("컬렉션 상세 데모")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(DemoCollectionDetailScenario.allCases) { scenario in
                        Button(scenario.title) {
                            path.append(Destination.detail(scenario.collectionID))
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("WSS Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .create:
                    createView
                case .edit(let id):
                    editView(id: id)
                case .list(let isEmpty):
                    listView(isEmpty: isEmpty)
                case .detail(let id):
                    detailView(id: id)
                case .searchNovel(let initialSelection):
                    searchNovelView(initialSelection: initialSelection)
                case .myLibrarySelect(let initialSelection):
                    myLibrarySelectView(initialSelection: initialSelection)
                }
            }
        }
    }

    @ViewBuilder
    private var createView: some View {
        switch dataSource {
        case .mock:
            CollectionFeatureFactory.makeCreateCollectionView(
                createCollectionUseCase: DemoCreateCollectionUseCase(),
                logger: consoleLogger,
                pendingNovelSelection: $pendingNovelSelection,
                onAddNovelTapped: handleAddNovelTapped,
                onAuthenticationRequired: handleAuthenticationRequired
            )
        case .live:
            makeLiveCreateView()
        }
    }

    @ViewBuilder
    private func editView(id: CollectionID) -> some View {
        switch dataSource {
        case .mock:
            CollectionFeatureFactory.makeEditCollectionView(
                id: id,
                updateCollectionUseCase: DemoUpdateCollectionUseCase(),
                loadCollectionDetailUseCase: DemoLoadCollectionDetailUseCase(),
                logger: consoleLogger,
                pendingNovelSelection: $pendingNovelSelection,
                onAddNovelTapped: handleAddNovelTapped,
                onAuthenticationRequired: handleAuthenticationRequired
            )
        case .live:
            makeLiveEditView(id: id)
        }
    }

    @ViewBuilder
    private func listView(isEmpty: Bool) -> some View {
        switch dataSource {
        case .mock:
            CollectionFeatureFactory.makeCollectionListView(
                userID: UserID(10049),
                loadCollectionsUseCase: DemoLoadCollectionsUseCase(isEmpty: isEmpty),
                loadLikedCollectionsUseCase: DemoLoadLikedCollectionsUseCase(isEmpty: isEmpty),
                logger: consoleLogger,
                onAuthenticationRequired: handleAuthenticationRequired,
                onCreateTapped: { path.append(Destination.create) },
                onCollectionSelected: { id in path.append(Destination.detail(id)) }
            )
        case .live:
            makeLiveListView()
        }
    }

    /// Mock 전용(실서버는 목록 화면에서 카드를 탭해 진입하는 경로만 유효 — 위 바로가기 주석 참고).
    private func detailView(id: CollectionID) -> some View {
        CollectionFeatureFactory.makeCollectionDetailView(
            id: id,
            loadCollectionDetailUseCase: DemoLoadCollectionDetailUseCase(),
            collectionLikeUseCase: DemoCollectionLikeUseCase(),
            deleteCollectionUseCase: DemoDeleteCollectionUseCase(),
            logger: consoleLogger,
            onAuthenticationRequired: handleAuthenticationRequired,
            onNovelTapped: handleNovelTapped,
            onEditTapped: { path.append(Destination.edit(id)) }
        )
    }

    @ViewBuilder
    private func searchNovelView(initialSelection: [CollectionNovel]) -> some View {
        switch dataSource {
        case .mock:
            CollectionFeatureFactory.makeSearchNovelView(
                initialSelection: initialSelection,
                searchNovelUseCase: DemoSearchNovelUseCase(),
                logger: consoleLogger,
                onConfirm: handleSearchNovelConfirm,
                onLibrarySelectTapped: handleLibrarySelectTapped,
                onAuthenticationRequired: handleAuthenticationRequired
            )
        case .live:
            makeLiveSearchNovelView(initialSelection: initialSelection)
        }
    }

    @ViewBuilder
    private func myLibrarySelectView(initialSelection: [CollectionNovel]) -> some View {
        switch dataSource {
        case .mock:
            CollectionFeatureFactory.makeMyLibrarySelectView(
                initialSelection: initialSelection,
                loadMyLibraryUseCase: DemoLoadMyLibraryUseCase(),
                logger: consoleLogger,
                onConfirm: handleLibrarySelectConfirm,
                onAuthenticationRequired: handleAuthenticationRequired
            )
        case .live:
            makeLiveMyLibrarySelectView(initialSelection: initialSelection)
        }
    }

    // MARK: - 화면 전환 콜백 (App 조정 계층 역할)

    /// "작품 추가" 타일 탭 → 검색 화면으로 push. 현재 선택을 path payload로 그대로 실어 보낸다(위
    /// `Destination.searchNovel` 문서의 레이스 회피 이유 참고).
    private func handleAddNovelTapped(_ currentSelection: [CollectionNovel]) {
        path.append(Destination.searchNovel(currentSelection))
    }

    /// 검색 화면의 "완료" 확정 → 생성/수정 화면까지 1단계 pop, 결과는 `pendingNovelSelection`으로.
    private func handleSearchNovelConfirm(_ novels: [CollectionNovel]) {
        pendingNovelSelection = novels
        path.removeLast(1)
    }

    /// 검색 화면의 "서재에서 추가" 탭 → 서재 선택 화면으로 push. 지금까지 고른 걸 path payload로
    /// 그대로 실어 보낸다.
    private func handleLibrarySelectTapped(_ currentSelection: [CollectionNovel]) {
        path.append(Destination.myLibrarySelect(currentSelection))
    }

    /// 서재 선택 화면의 "추가" 확정 → 생성/수정 화면까지 2단계 pop(검색 화면도 함께 건너뜀 — 기획
    /// 확정 사항, `CollectionFeature/CLAUDE.md`의 "2단계 pop" 정본 참고. 이전엔 Feature 모듈 안에서
    /// 단일 boolean으로 서브트리를 걷어냈지만, 지금은 App이 두 path 요소를 한 번에 pop한다).
    private func handleLibrarySelectConfirm(_ novels: [CollectionNovel]) {
        pendingNovelSelection = novels
        path.removeLast(2)
    }

    /// 인증 만료(세션 죽음) 콜백. 실제 앱은 App 조정 계층이 로그인 화면으로 전환한다 — Demo는 로그만.
    private func handleAuthenticationRequired() {
        consoleLogger.info("인증 만료 → 로그인 진입 요청")
    }

    /// 작품 상세 진입 콜백. `NovelDetailFeature`로 갈 실제 배선은 App 몫이라(#201, `docs/TODO.md` 참고)
    /// Demo는 로그만 남긴다(`handleAuthenticationRequired`와 동일한 판단).
    private func handleNovelTapped(_ novelID: NovelID) {
        consoleLogger.info("작품 상세 진입 요청: \(novelID)")
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

    // 서재 조회 — LibraryFeatureDemoApp의 실서버 배관과 동일(내 서재는 저장된 userID를 쓰므로
    // Demo가 직접 세팅). NovelData의 KeywordRepository도 함께 필요하다(DefaultLoadMyLibraryUseCase
    // 시그니처 참고).
    @MainActor
    private func makeLiveNovelRepository(client: NetworkingClient) -> (novel: NovelRepository, keyword: KeywordRepository) {
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
        return (novelRepository, keywordRepository)
    }

    @MainActor
    private func makeLiveCreateView() -> some View {
        let client = makeLiveClient()
        let repository = CollectionDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "CollectionData", underlying: consoleLogger)
        )
        return CollectionFeatureFactory.makeCreateCollectionView(
            createCollectionUseCase: DefaultCreateCollectionUseCase(collectionRepository: repository),
            logger: consoleLogger,
            pendingNovelSelection: $pendingNovelSelection,
            onAddNovelTapped: handleAddNovelTapped,
            onAuthenticationRequired: handleAuthenticationRequired
        )
    }

    @MainActor
    private func makeLiveEditView(id: CollectionID) -> some View {
        let client = makeLiveClient()
        let repository = CollectionDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "CollectionData", underlying: consoleLogger)
        )
        return CollectionFeatureFactory.makeEditCollectionView(
            id: id,
            updateCollectionUseCase: DefaultUpdateCollectionUseCase(collectionRepository: repository),
            loadCollectionDetailUseCase: DefaultLoadCollectionDetailUseCase(collectionRepository: repository),
            logger: consoleLogger,
            pendingNovelSelection: $pendingNovelSelection,
            onAddNovelTapped: handleAddNovelTapped,
            onAuthenticationRequired: handleAuthenticationRequired
        )
    }

    @MainActor
    private func makeLiveListView() -> some View {
        let client = makeLiveClient()
        let repository = CollectionDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "CollectionData", underlying: consoleLogger)
        )
        return CollectionFeatureFactory.makeCollectionListView(
            userID: UserID(10049),
            loadCollectionsUseCase: DefaultLoadCollectionsUseCase(collectionRepository: repository),
            loadLikedCollectionsUseCase: DefaultLoadLikedCollectionsUseCase(collectionRepository: repository),
            logger: consoleLogger,
            onAuthenticationRequired: handleAuthenticationRequired,
            onCreateTapped: { path.append(Destination.create) },
            onCollectionSelected: { id in path.append(Destination.detail(id)) }
        )
    }

    @MainActor
    private func makeLiveSearchNovelView(initialSelection: [CollectionNovel]) -> some View {
        let client = makeLiveClient()
        let searchRepository = SearchDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "SearchData", underlying: consoleLogger)
        )
        return CollectionFeatureFactory.makeSearchNovelView(
            initialSelection: initialSelection,
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: searchRepository),
            logger: consoleLogger,
            onConfirm: handleSearchNovelConfirm,
            onLibrarySelectTapped: handleLibrarySelectTapped,
            onAuthenticationRequired: handleAuthenticationRequired
        )
    }

    @MainActor
    private func makeLiveMyLibrarySelectView(initialSelection: [CollectionNovel]) -> some View {
        let client = makeLiveClient()
        let (novelRepository, keywordRepository) = makeLiveNovelRepository(client: client)
        return CollectionFeatureFactory.makeMyLibrarySelectView(
            initialSelection: initialSelection,
            loadMyLibraryUseCase: DefaultLoadMyLibraryUseCase(
                novelRepository: novelRepository,
                keywordRepository: keywordRepository
            ),
            logger: consoleLogger,
            onConfirm: handleLibrarySelectConfirm,
            onAuthenticationRequired: handleAuthenticationRequired
        )
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

private struct DemoUpdateCollectionUseCase: UpdateCollectionUseCase {
    func execute(id: CollectionID, draft: CollectionDraft) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 500_000_000)
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
    /// true면 첫 페이지부터 빈 배열을 돌려준다 — 컬렉션 목록의 빈 상태("아직 만든 컬렉션이 없어요" +
    /// "내 컬렉션" 탭 전용 CTA) 데모용, `CollectionFeatureDemoApp.listView(isEmpty:)`가 넘긴다.
    var isEmpty = false

    func execute(userID: UserID, cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return DemoCollectionCardPage.page(cursor: cursor, namePrefix: "내 컬렉션", isEmpty: isEmpty)
    }
}

private struct DemoLoadLikedCollectionsUseCase: LoadLikedCollectionsUseCase {
    /// true면 첫 페이지부터 빈 배열을 돌려준다 — 컬렉션 목록의 빈 상태("아직 좋아요한 컬렉션이
    /// 없어요", CTA 없음) 데모용, `CollectionFeatureDemoApp.listView(isEmpty:)`가 넘긴다.
    var isEmpty = false

    func execute(cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return DemoCollectionCardPage.page(cursor: cursor, namePrefix: "좋아요한 컬렉션", isEmpty: isEmpty)
    }
}

/// 컬렉션 상세 데모 바로가기용 예약 id — `DemoLoadCollectionDetailUseCase`가 이미 짝수/4배수 여부로
/// 나누는 3가지 상태에 맞춰 대표 id를 하나씩 골랐다(`demoPrivateProfileUserID` 같은 다른 Demo 앱의
/// "예약 값으로 시나리오 분기" 관례와 동일 발상).
private enum DemoCollectionDetailScenario: CaseIterable, Identifiable {
    case others
    case mine
    case minePrivate

    var id: Self { self }

    /// `Button`에 넘길 실제 `CollectionID` — case명과 헷갈리지 않도록 별도 프로퍼티로 뺐다
    /// (`Identifiable.id`는 `ForEach` 식별용).
    var collectionID: CollectionID {
        switch self {
        case .others: CollectionID(1)
        case .mine: CollectionID(2)
        case .minePrivate: CollectionID(4)
        }
    }

    var title: String {
        switch self {
        case .others: "타인 컬렉션"
        case .mine: "내 컬렉션 (공개)"
        case .minePrivate: "내 컬렉션 (비공개)"
        }
    }
}

/// 컬렉션 상세 Mock — id의 짝수/4배수 여부로 3가지 화면 상태를 전부 시연한다: 홀수(타인 컬렉션,
/// 좋아요+공유하기), 4의 배수(내 컬렉션·비공개, 좋아요+"나만 보는 컬렉션"+더보기), 그 외 짝수(내
/// 컬렉션·공개, 더보기 노출). 목록 카드가 이미 짝수 id에 `isPrivate`를 주는 것과 결이 맞다
/// (`DemoCollectionCardPage`).
private struct DemoLoadCollectionDetailUseCase: LoadCollectionDetailUseCase {
    func execute(id: CollectionID, sortType: SortType) async throws(RepositoryError) -> CollectionDetail {
        try? await Task.sleep(nanoseconds: 300_000_000)
        let isMine = id.value.isMultiple(of: 2)
        let isPrivate = isMine && id.value.isMultiple(of: 4)
        // 3의 배수 인덱스는 제목을 길게 줘서 2줄로 꺾이는 케이스도 시연한다 — 짧은 제목만 있으면
        // 표지 폭이 제목 줄 수에 밀려 좁아지는 회귀(`novelCell`이 한때 표지+제목을 한 `.frame(height:)`
        // 로 묶어 실제로 겪었던 버그)를 Mock에서 못 잡는다.
        let novels = (1...9).map { index in
            let title = index.isMultiple(of: 3)
                ? "아주 길게 늘어져서 두 줄로 꺾이는 작품 제목 \(id.value)-\(index)"
                : "작품 \(id.value)-\(index)"
            return CollectionNovel(id: NovelID(id.value * 10 + index), title: title, author: "작가 \(index)", thumbnailImage: nil)
        }
        let sorted = sortType == .recent ? novels : novels.reversed()
        return CollectionDetail(
            id: id,
            name: "컬렉션 \(id.value)",
            description: id.value.isMultiple(of: 3) ? nil : "존잼 수준이 정도를 넘음",
            owner: Author(nickname: "판소덕", profileImage: nil),
            isMine: isMine,
            isPrivate: isPrivate,
            representativeNovelID: novels[0].id,
            novels: Array(sorted),
            likeCount: 100,
            isLiked: false
        )
    }
}

private struct DemoCollectionLikeUseCase: CollectionLikeUseCase {
    func like(id: CollectionID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }

    func unlike(id: CollectionID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

private struct DemoDeleteCollectionUseCase: DeleteCollectionUseCase {
    func execute(id: CollectionID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

/// 두 목록 Mock이 공유하는 페이지 생성기 — 무한스크롤(3페이지)·표지 5슬롯 중 일부만 채워지는 카드
/// (recentNovels < novelCount, 오버플로 배지 없이 기본 표지로 폴백)·비공개 태그·설명 없는 카드까지
/// `CollectionListView`의 주요 분기를 한 번씩 보여준다.
private enum DemoCollectionCardPage {
    static let pageSize = 6
    private static let demoPageCount = 3

    static func page(cursor: String?, namePrefix: String, isEmpty: Bool = false) -> (CursorPaginated<CollectionCard>, Int) {
        // 빈 상태 데모는 cursor(페이지) 무관하게 항상 빈 배열 — 첫 진입에서 바로 emptySection이 보여야 한다.
        guard !isEmpty else {
            return (CursorPaginated(items: [], hasNext: false, nextCursor: nil), 0)
        }
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
