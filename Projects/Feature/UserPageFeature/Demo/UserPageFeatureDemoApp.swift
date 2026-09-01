//
//  UserPageFeatureDemoApp.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftUI

import UserPageFeature
import BaseDomain
import NovelDomain
import ProfileDomain
import FeedDomain
import SocialDomain
import CollectionDomain
import BaseData
import NovelData
import ProfileData
import FeedData
import SocialData
import CollectionData
import Logger
import Networking
import DesignSystem
import WSSComponent

@main
struct UserPageFeatureDemoApp: App {

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

// MARK: - Root: Mock/실서버 선택 → 내 화면/남의 화면 선택 순으로 단계별 네비게이션

// Demo가 App(DI) 역할을 대행해 UseCase를 조립한다.
// Mock = 인메모리(흐름 시연), 실서버 = NetworkingClient + 실제 Repository.
private enum DemoDataSource: String, CaseIterable, Identifiable {
    case mock = "Mock"
    case live = "실서버"
    var id: String { rawValue }
}

/// 1단계: 데이터 소스(Mock/실서버) 선택.
private struct DemoRootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("데이터 소스를 선택하세요")
                    .font(.headline)

                ForEach(DemoDataSource.allCases) { dataSource in
                    NavigationLink(dataSource.rawValue) {
                        DemoScreenSelectionView(dataSource: dataSource)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("UserPageFeature Demo")
        }
    }
}

/// 2단계: 내 화면(MyPage)/남의 화면(UserPage) 선택. 남의 화면은 대상 유저 ID를 입력받는다.
private struct DemoScreenSelectionView: View {
    let dataSource: DemoDataSource

    @State private var isEnteringUserID = false
    @State private var userIDInput = "10016"
    /// 차단 성공 시 UserPage가 pop되고 이 화면(직전 뷰)으로 돌아온다 — App 4탭 Root의 `NavigationStack` +
    /// `.showWSSToast(.blockUser)` 배선(#221)을 Demo에서 재현해 seam→복귀 화면 토스트를 확인한다.
    @State private var blockedNickname: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink("내 화면 (MyPage)") {
                    DemoFactory.makeMypageView(dataSource: dataSource)
                }
                .buttonStyle(.borderedProminent)

                Button("남의 화면 (UserPage)") {
                    withAnimation { isEnteringUserID = true }
                }
                .buttonStyle(.bordered)

                if isEnteringUserID {
                    HStack(spacing: 8) {
                        TextField("유저 ID", text: $userIDInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)

                        if let id = Int(userIDInput) {
                            NavigationLink("이동") {
                                DemoFactory.makeUserPageView(
                                    dataSource: dataSource,
                                    userID: UserID(id),
                                    onUserBlocked: { blockedNickname = $0 }
                                )
                            }
                        }
                    }
                    .transition(.opacity)
                }

                // Mock 전용 — 예약 userID(`DemoCollectionScenario`)로 컬렉션 개수 시나리오를 바로 시연한다.
                // 실서버는 실제 데이터를 그대로 조회하므로 이 바로가기가 의미가 없다.
                if dataSource == .mock {
                    Divider().padding(.vertical, 8)

                    Text("컬렉션 개수별 데모 (MyPage)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(DemoCollectionScenario.allCases) { scenario in
                        NavigationLink(scenario.title) {
                            DemoFactory.makeMypageView(dataSource: dataSource, userID: scenario.userID)
                        }
                        .buttonStyle(.bordered)
                    }

                    Divider().padding(.vertical, 8)

                    Text("컬렉션 개수별 데모 (UserPage)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(DemoCollectionScenario.allCases) { scenario in
                        NavigationLink(scenario.title) {
                            DemoFactory.makeUserPageView(dataSource: dataSource, userID: scenario.userID)
                        }
                        .buttonStyle(.bordered)
                    }

                    Divider().padding(.vertical, 8)

                    // 특수 상태(없는 유저·비공개 프로필)는 예약 userID로 Mock 응답을 분기한다 — 키보드 입력 없이
                    // 바로 진입하도록 바로가기로 둔다(userID 입력칸 + 이동으로도 같은 값을 넣을 수 있다).
                    Text("특수 상태 데모 (UserPage)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    NavigationLink("없는 유저 (998 · USER-018)") {
                        DemoFactory.makeUserPageView(dataSource: dataSource, userID: demoNotFoundProfileUserID)
                    }
                    .buttonStyle(.bordered)

                    NavigationLink("비공개 프로필 (999)") {
                        DemoFactory.makeUserPageView(dataSource: dataSource, userID: demoPrivateProfileUserID)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle(dataSource.rawValue)
        .showWSSToast(
            isPresented: Binding(
                get: { blockedNickname != nil },
                set: { if !$0 { blockedNickname = nil } }
            ),
            type: .blockUser(nickname: blockedNickname ?? "")
        )
    }
}

/// 컬렉션 섹션의 개수별 노출(3개 이상/2개/1개/0개)을 확인하기 위한 예약 userID 시나리오.
/// MyPage·UserPage 둘 다에서 재사용한다 — `loadCollectionPreviewsUseCase.execute(userID:...)`의
/// `userID`는 두 화면 모두 컬렉션 미리보기에만 쓰이고(MyPage의 프로필·장르·작품취향·서재통계는
/// `.me` 기준이라 이 값과 무관) 화면별 노출 정책만 다르다 — MyPage는 0개여도 헤더는 항상 보이고
/// 미리보기 카드만 숨는 반면, UserPage는 0개면 섹션 자체가 통째로 숨는다(`UserPageFeature/CLAUDE.md`).
/// `demoPrivateProfileUserID`(999, 비공개 프로필 시나리오)와 동일한 관례 — 특정 userID로 Mock 응답을 분기한다.
private enum DemoCollectionScenario: CaseIterable, Identifiable {
    case threeOrMore
    case two
    case one
    case zero

    var id: Self { self }

    var userID: UserID {
        switch self {
        case .threeOrMore: UserID(9973)
        case .two: UserID(9972)
        case .one: UserID(9971)
        case .zero: UserID(9970)
        }
    }

    var title: String {
        switch self {
        case .threeOrMore: "컬렉션 3개 이상"
        case .two: "컬렉션 2개"
        case .one: "컬렉션 1개"
        case .zero: "컬렉션 0개"
        }
    }
}

/// 3단계: 실제 화면 조립. Mock은 인메모리 UseCase, 실서버는 NetworkingClient + 실제 Repository로 조립한다.
@MainActor
private enum DemoFactory {
    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    static let consoleLogger = ConsoleLogger()
    /// Mock 데이터 소스의 "서버" 역할(MyPage 전용) — 편집 화면에서 저장한 값을 마이페이지 조회가 그대로
    /// 돌려받도록 인메모리로 들고 있는다. 없으면 Mock 모드에서 완료를 눌러도 항상 하드코딩된 초기값만 보인다.
    static let demoProfileStore = DemoProfileStore()
    /// 컬렉션 미리보기(`fetchCollections`)가 명시적으로 요구하는 값 — 실서버 조립(`makeLiveRepositories`)의
    /// `UserDefaultsStorage` userID(10049)와 맞춘다.
    static let demoUserID = UserID(10049)

    @ViewBuilder
    static func makeMypageView(dataSource: DemoDataSource) -> some View {
        makeMypageView(dataSource: dataSource, userID: demoUserID)
    }

    /// 컬렉션 개수 시나리오 바로가기 전용 — `userID`만 예약 userID(`DemoCollectionScenario`)로 바꿔
    /// 컬렉션 미리보기 개수를 오버라이드한다. 다른 데이터(프로필·장르·작품취향·서재통계)는 전부 `.me`
    /// 기준이라 이 값과 무관하다.
    @ViewBuilder
    static func makeMypageView(dataSource: DemoDataSource, userID: UserID) -> some View {
        switch dataSource {
        case .mock:
            MypageFeatureFactory.makeView(
                userID: userID,
                loadProfileUseCase: DemoLoadProfileUseCase(store: demoProfileStore),
                loadGenrePreferencesUseCase: DemoLoadGenrePreferencesUseCase(),
                loadNovelPreferencesUseCase: DemoLoadNovelPreferencesUseCase(),
                loadRegisteredNovelStatsUseCase: DemoLoadRegisteredNovelStatsUseCase(),
                loadCollectionPreviewsUseCase: DemoLoadCollectionPreviewsUseCase(),
                logger: consoleLogger,
                onCollectionTapped: { consoleLogger.info("컬렉션 뷰로 이동") },
                onCollectionItemTapped: { consoleLogger.info("컬렉션 상세로 이동: \($0)") },
                onEditProfileTapped: { consoleLogger.info("프로필 편집 진입") },
                onSettingTapped: { consoleLogger.info("설정 진입") },
                onLibraryTapped: { consoleLogger.info("서재 탭으로 전환") }
            )
        case .live:
            makeMypageLiveView()
        }
    }

    @ViewBuilder
    static func makeUserPageView(
        dataSource: DemoDataSource,
        userID: UserID,
        onUserBlocked: @escaping (String) -> Void = { _ in }
    ) -> some View {
        switch dataSource {
        case .mock:
            UserPageFeatureFactory.makeView(
                userID: userID,
                loadProfileUseCase: DemoLoadOtherUserProfileUseCase(),
                loadGenrePreferencesUseCase: DemoLoadGenrePreferencesUseCase(),
                loadNovelPreferencesUseCase: DemoLoadNovelPreferencesUseCase(),
                loadUserRegisteredNovelStatsUseCase: DemoLoadUserRegisteredNovelStatsUseCase(),
                loadCollectionPreviewsUseCase: DemoLoadCollectionPreviewsUseCase(),
                loadUserFeedsUseCase: DemoLoadUserFeedsUseCase(),
                feedLikeUseCase: DemoFeedLikeUseCase(),
                blockUserUseCase: DemoBlockUserUseCase(),
                reportSpoilerFeedUseCase: DemoReportSpoilerFeedUseCase(),
                reportImproperFeedUseCase: DemoReportImproperFeedUseCase(),
                logger: consoleLogger,
                onFeedListTapped: { userID, nickname, _ in
                    consoleLogger.info("전체 피드 목록 진입 요청: \(userID), \(nickname)")
                },
                onCollectionItemTapped: { consoleLogger.info("컬렉션 상세로 이동: \($0)") },
                onCollectionListTapped: { consoleLogger.info("컬렉션 목록으로 이동") },
                onUserBlocked: onUserBlocked
            )
        case .live:
            makeUserPageLiveView(userID: userID)
        }
    }

    // MARK: - 실서버 조립

    // NetworkingConfig.baseURL로 호출하고, DemoSessionTokenStore가 TEST_API_KEY를
    // accessToken으로 제공해 .requireToken 엔드포인트를 인증한다.
    private static func makeMypageLiveView() -> some View {
        let (profileRepository, novelRepository, keywordRepository, _) = makeLiveRepositories()
        let collectionRepository = CollectionDataFactory.makeRepository(
            network: NetworkingClient(
                logger: DefaultNetworkLogger(base: consoleLogger),
                tokenStore: DemoSessionTokenStore()
            ),
            logger: DataLogger(moduleName: "CollectionData", underlying: consoleLogger)
        )
        return MypageFeatureFactory.makeView(
            userID: demoUserID,
            loadProfileUseCase: DefaultLoadProfileUseCase(profileRepository: profileRepository),
            loadGenrePreferencesUseCase: DefaultLoadGenrePreferencesUseCase(profileRepository: profileRepository),
            loadNovelPreferencesUseCase: DefaultLoadNovelPreferencesUseCase(
                profileRepository: profileRepository,
                keywordRepository: keywordRepository
            ),
            loadRegisteredNovelStatsUseCase: DefaultLoadRegisteredNovelStatsUseCase(novelRepository: novelRepository),
            loadCollectionPreviewsUseCase: DefaultLoadCollectionPreviewsUseCase(collectionRepository: collectionRepository),
            logger: consoleLogger,
            onCollectionTapped: { consoleLogger.info("컬렉션 뷰로 이동") },
            onCollectionItemTapped: { consoleLogger.info("컬렉션 상세로 이동: \($0)") },
            onEditProfileTapped: { consoleLogger.info("프로필 편집 진입") },
            onSettingTapped: { consoleLogger.info("설정 진입") },
            onLibraryTapped: { consoleLogger.info("서재 탭으로 전환") }
        )
    }

    private static func makeUserPageLiveView(userID: UserID) -> some View {
        let (profileRepository, novelRepository, keywordRepository, feedRepository) = makeLiveRepositories()
        let socialRepository = SocialDataFactory.makeSocialRepository(
            client: NetworkingClient(
                logger: DefaultNetworkLogger(base: consoleLogger),
                tokenStore: DemoSessionTokenStore()
            ),
            logger: DataLogger(moduleName: "SocialData", underlying: consoleLogger)
        )
        let collectionRepository = CollectionDataFactory.makeRepository(
            network: NetworkingClient(
                logger: DefaultNetworkLogger(base: consoleLogger),
                tokenStore: DemoSessionTokenStore()
            ),
            logger: DataLogger(moduleName: "CollectionData", underlying: consoleLogger)
        )
        return UserPageFeatureFactory.makeView(
            userID: userID,
            loadProfileUseCase: DefaultLoadProfileUseCase(profileRepository: profileRepository),
            loadGenrePreferencesUseCase: DefaultLoadGenrePreferencesUseCase(profileRepository: profileRepository),
            loadNovelPreferencesUseCase: DefaultLoadNovelPreferencesUseCase(
                profileRepository: profileRepository,
                keywordRepository: keywordRepository
            ),
            loadUserRegisteredNovelStatsUseCase: DefaultLoadUserRegisteredNovelStatsUseCase(novelRepository: novelRepository),
            loadCollectionPreviewsUseCase: DefaultLoadCollectionPreviewsUseCase(collectionRepository: collectionRepository),
            loadUserFeedsUseCase: DefaultLoadUserFeedsUseCase(feedRepository: feedRepository),
            feedLikeUseCase: DefaultLikeUseCase(feedRepository: feedRepository),
            blockUserUseCase: DefaultBlockUserUseCase(repository: socialRepository),
            reportSpoilerFeedUseCase: DefaultReportSpoilerFeedUseCase(repository: socialRepository),
            reportImproperFeedUseCase: DefaultReportImproperFeedUseCase(repository: socialRepository),
            logger: consoleLogger,
            onFeedListTapped: { userID, nickname, _ in
                consoleLogger.info("전체 피드 목록 진입 요청: \(userID), \(nickname)")
            },
            onCollectionItemTapped: { consoleLogger.info("컬렉션 상세로 이동: \($0)") },
            onCollectionListTapped: { consoleLogger.info("컬렉션 목록으로 이동") }
        )
    }

    private static func makeLiveRepositories() -> (ProfileRepository, NovelRepository, KeywordRepository, FeedRepository) {
        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )

        let localStorage = UserDefaultsStorage()
        localStorage.set(.userID, 10049)

        let profileRepository = ProfileDataFactory.makeProfileRepository(
            client: client,
            localStorage: localStorage,
            logger: DataLogger(moduleName: "ProfileData", underlying: consoleLogger)
        )
        let novelRepository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: localStorage,
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
        // 키워드 캐시(keywords.json)가 없으면 fetchKeywords()가 매번 cache error를 낸다 —
        // 실제 App은 아직 startup sync를 안 하므로, Demo가 그 역할을 대신 1회 트리거한다.
        Task { await keywordRepository.syncKeywords() }

        return (profileRepository, novelRepository, keywordRepository, feedRepository)
    }
}

// MARK: - Demo In-Memory "서버" (Mock)

/// Mock 데이터 소스의 상태를 화면 간에 공유하는 인메모리 저장소(MyPage 전용).
/// 이게 없으면 편집 화면에서 완료를 눌러도 마이페이지 조회 Mock은 항상 하드코딩된 초기값만 돌려준다.
private final class DemoProfileStore {
    var characterID = 1
    var nickname = "구리구리스"
    var introduction = "백덕수 작가입니다. 반갑습니다."
    var genrePreferences: [GenrePreference] = [
        GenrePreference(genre: .romance, count: 2),
        GenrePreference(genre: .BL, count: 1003)
    ]

    static let characters: [ProfileCharacter] = (1...20).map { index in
        ProfileCharacter(
            id: index,
            name: "팬텀 \(index)",
            line: "만나서 반가워요, %s",
            representativeImage: URL(string: "https://i.pinimg.com/736x/5d/c4/68/5dc46859de623b667c4ed3273c99071e.jpg"),
            thumbnailImage: URL(string: "https://i.pinimg.com/736x/5d/c4/68/5dc46859de623b667c4ed3273c99071e.jpg"),
            isRepresentative: index == 1
        )
    }
}

// MARK: - Demo UseCases (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요).

/// MyPage(내 화면) 전용 — 편집 화면에서 저장한 값이 그대로 반영되도록 공유 `DemoProfileStore`를 읽는다.
private struct DemoLoadProfileUseCase: LoadProfileUseCase {
    let store: DemoProfileStore

    func execute(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return Profile(
            nickname: store.nickname,
            introduction: store.introduction,
            characterImage: DemoProfileStore.characters.first { $0.id == store.characterID }?.representativeImage,
            isPublic: true,
            genrePreferences: []
        )
    }
}

/// UserPage(남의 화면) 전용 — 편집 대상이 아니라 조회 전용이라 공유 store 없이 고정 값을 돌려준다.
private struct DemoLoadOtherUserProfileUseCase: LoadProfileUseCase {
    func execute(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        try? await Task.sleep(nanoseconds: 500_000_000)
        // userID 998 = "없는 유저"(USER-018 → .notFound) 시연 — 데모 메뉴 userID 입력칸에 998 입력.
        if case .user(demoNotFoundProfileUserID) = target {
            throw .notFound
        }
        return Profile(
            nickname: "구리구리스",
            introduction: "백덕수 작가입니다. 반갑습니다.백덕수 작가입니다. 반갑습니다.",
            characterImage: URL(string: "https://i.pinimg.com/736x/d7/18/03/d71803d12d1a305bd0626733ddbacd92.jpg"),
            isPublic: true,
            genrePreferences: []
        )
    }
}

private struct DemoLoadProfileCharacterUseCase: LoadProfileCharacterUseCase {
    func execute() async throws(RepositoryError) -> [ProfileCharacter] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return DemoProfileStore.characters
    }
}

private struct DemoLoadInitialProfileUseCase: LoadInitialProfileUseCase {
    let store: DemoProfileStore

    func execute() async throws(RepositoryError) -> ProfileDraft {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return ProfileDraft(
            characterID: store.characterID,
            nickname: store.nickname,
            introduction: store.introduction,
            genrePreferences: store.genrePreferences
        )
    }
}

private struct DemoValidateNicknameUseCase: ValidateNicknameUseCase {
    func execute(_ nickname: String) async throws(RepositoryError) -> Bool {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return nickname != "중복닉네임"
    }
}

private struct DemoUpdateProfileUseCase: UpdateProfileUseCase {
    let store: DemoProfileStore

    func execute(_ draft: ProfileDraft) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 500_000_000)
        store.characterID = draft.characterID
        store.nickname = draft.nickname.text
        store.introduction = draft.introduction
        store.genrePreferences = draft.genrePreferences
    }
}

/// 유저 ID `999`는 "비공개 프로필" 데모 시나리오(`RepositoryError.privateProfile`) 확인용 —
/// `USER-015` 응답을 이 세 UseCase(장르·작품 취향, 피드) 각각에서 흉내낸다.
private let demoPrivateProfileUserID = UserID(999)

/// 유저 ID `998`은 "없는 유저"(USER-018 → `RepositoryError.notFound`) 데모 시나리오 확인용 —
/// `DemoLoadOtherUserProfileUseCase`가 이 userID에 `.notFound`를 던져 "존재하지 않는 유저예요" 화면을 낸다.
private let demoNotFoundProfileUserID = UserID(998)

private struct DemoLoadGenrePreferencesUseCase: LoadGenrePreferencesUseCase {
    func execute(_ target: ProfileTarget) async throws(RepositoryError) -> [GenrePreference] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        if case .user(demoPrivateProfileUserID) = target {
            throw .privateProfile
        }
        return [
            GenrePreference(genre: .BL, count: 1003),
            GenrePreference(genre: .fantasy, count: 30),
            GenrePreference(genre: .romance, count: 2),
            GenrePreference(genre: .lightNovel, count: 3),
            GenrePreference(genre: .wuxia, count: 123)
        ]
    }
}

private struct DemoLoadNovelPreferencesUseCase: LoadNovelPreferencesUseCase {
    func execute(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference {
        try? await Task.sleep(nanoseconds: 500_000_000)
        if case .user(demoPrivateProfileUserID) = target {
            throw .privateProfile
        }
        return NovelPreference(
            attractivePoints: [.character, .relationship, .material],
            keywords: [
                KeywordPreference(keyword: Keyword(id: KeywordID(1), name: "안녕"), count: 2),
                KeywordPreference(keyword: Keyword(id: KeywordID(2), name: "궁중암투"), count: 5)
            ]
        )
    }
}

private struct DemoLoadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase {
    func execute() async throws(RepositoryError) -> RegisteredNovelStats {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return RegisteredNovelStats(interest: 4, watching: 30, watched: 1312, quit: 24)
    }
}

/// 마이페이지·타유저 페이지 공통 컬렉션 섹션 — "컬렉션 3개"(Figma 31613:89234) 상태를 기본값으로
/// 시연한다. 실제 목록 API를 `size`로 그대로 흉내낸다(`CollectionDomain/CLAUDE.md`의 "마이페이지 전용
/// API 없음" 계약과 동일한 모양). `DemoCollectionScenario`(9970~9973)의 예약 userID가 오면 그 개수로
/// 오버라이드한다 — 3개 이상/2개/1개/0개 시나리오 시연용(MyPage/UserPage 둘 다의 바로가기가 이 매핑을
/// 공유). 기본 진입점("내 화면 (MyPage)")은 `demoUserID`(10049)라 매핑에 없어 항상 3개 그대로다.
private struct DemoLoadCollectionPreviewsUseCase: LoadCollectionPreviewsUseCase {
    static let scenarioTotalCounts: [UserID: Int] = [
        UserID(9973): 5, // "3개 이상" — 미리보기는 3개까지만 보이지만 전체 개수는 더 있다
        UserID(9972): 2,
        UserID(9971): 1,
        UserID(9970): 0
    ]

    func execute(userID: UserID, size: Int) async throws(RepositoryError) -> ([CollectionPreview], Int) {
        try? await Task.sleep(nanoseconds: 500_000_000)
        let totalCount = Self.scenarioTotalCounts[userID] ?? 3
        let previewCount = min(size, totalCount)
        // totalCount 0(빈 시나리오)이면 `1...0`이 유효하지 않은 range라 별도 분기한다.
        let previews = previewCount > 0 ? (1...previewCount).map { index in
            CollectionPreview(
                id: CollectionID(index),
                name: "마이페이지 컬렉션 \(index)",
                representativeNovel: CollectionNovel(
                    id: NovelID(index),
                    title: "작품 \(index)",
                    author: "작가 \(index)",
                    thumbnailImage: nil
                )
            )
        } : []
        return (previews, totalCount)
    }
}

private struct DemoLoadUserRegisteredNovelStatsUseCase: LoadUserRegisteredNovelStatsUseCase {
    func execute(id: UserID) async throws(RepositoryError) -> RegisteredNovelStats {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return RegisteredNovelStats(interest: 4, watching: 30, watched: 1312, quit: 24)
    }
}

private struct DemoLoadUserFeedsUseCase: LoadUserFeedsUseCase {
    func execute(userID: UserID, nickname: String, profileImage: URL?, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        try? await Task.sleep(nanoseconds: 500_000_000)
        if userID == demoPrivateProfileUserID {
            throw .privateProfile
        }
        // 첫 페이지(커서 0)는 8개(미리보기 5개 초과 → "전체보기" 버튼 노출 확인용) + hasNext true,
        // 다음 페이지(커서 8)는 나머지 4개 + hasNext false로 끝맺는다(전체 목록 무한스크롤 확인용).
        if lastFeedID == FeedID(8) {
            let feeds = (9...12).map { index in
                TotalFeed(
                    feedId: FeedID(index),
                    createdDate: "2026년 7월 25일",
                    content: "대학원생이 환생해서 대학원생이 됨. 주인공 완전 갓갓! \(index)",
                    author: Author(userId: userID, nickname: nickname, profileImage: profileImage),
                    likeCount: 13,
                    isLiked: false,
                    commentCount: 3,
                    connectedNovel: ConnectedNovel(id: NovelID(1), title: "스즈미야 하루히의 무료", genre: .modernFantasy, rating: 4.3),
                    isSpoiler: false,
                    isModified: false,
                    isPublic: true,
                    isMyFeed: false,
                    imageCount: 0
                )
            }
            return Paginated(items: feeds, hasNext: false)
        }
        guard lastFeedID == FeedID(0) else {
            return Paginated(items: [], hasNext: false)
        }
        let feeds = (1...8).map { index in
            TotalFeed(
                feedId: FeedID(index),
                createdDate: "2026년 7월 25일",
                content: "대학원생이 환생해서 대학원생이 됨. 주인공 완전 갓갓! \(index)",
                author: Author(userId: userID, nickname: nickname, profileImage: profileImage),
                likeCount: 13,
                isLiked: false,
                commentCount: 3,
                connectedNovel: ConnectedNovel(id: NovelID(1), title: "스즈미야 하루히의 무료", genre: .modernFantasy, rating: 4.3),
                isSpoiler: false,
                isModified: false,
                isPublic: true,
                isMyFeed: false,
                imageCount: 0
            )
        }
        return Paginated(items: feeds, hasNext: true)
    }
}

private struct DemoFeedLikeUseCase: FeedLikeUseCase {
    func like(feedID: FeedID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }

    func unlike(feedID: FeedID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

private struct DemoBlockUserUseCase: BlockUserUseCase {
    func execute(id: UserID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

private struct DemoReportSpoilerFeedUseCase: ReportSpoilerFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

private struct DemoReportImproperFeedUseCase: ReportImproperFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}
