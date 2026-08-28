//
//  SettingFeatureDemoApp.swift
//  SettingFeatureDemo
//
//  Created by Seoyeon Choi on 7/15/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import SettingFeature
import BaseDomain
import ProfileDomain
import SocialDomain
import NotificationDomain
import AuthDomain
import NovelDomain
import BaseData
import ProfileData
import SocialData
import NotificationData
import AuthData
import NovelData
import Logger
import Networking
import PushAuthorization
import DesignSystem
import WSSComponent

@main
struct SettingFeatureDemoApp: App {
    init() {
        DesignSystemFontFamily.registerAllCustomFonts()
        Self.seedLocalGenderAndBirthIfNeeded()
    }

    /// `loadLocalGenderAndBirth()`는 userDefaults 미스 시 서버로 폴백하지만, Demo는 그 폴백 경로를
    /// 타지 않고 항상 로컬 값을 바로 보여주도록 최초 실행 시 한 번 심어둔다(실제 값이 있으면 덮어쓰지 않음).
    private static func seedLocalGenderAndBirthIfNeeded() {
        let storage = UserDefaultsStorage()
        if storage.get(.gender) == nil {
            storage.set(.gender, "FEMALE")
        }
        if storage.get(.birthYear) == nil {
            storage.set(.birthYear, 2001)
        }
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

    /// 시스템 푸시 권한 상태(#193) — 서버 데이터와 무관해 `dataSource`와 별개 축으로 둔다.
    /// 실기기/시뮬레이터 설정을 직접 바꾸지 않고도 세 상태를 전부 시연하기 위한 Demo 전용 시나리오.
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

    /// Demo가 대행하는 App Destination — 모듈 CLAUDE.md의 "전부 App이 조립" 원칙(#201)에 맞춰, 이
    /// 화면들을 여기서 `NavigationPath`로 push한다(`SettingFeature` 안엔 `WithdrawFlowView` 하나만
    /// 예외로 로컬 내비게이션이 남아있다).
    private enum Destination: Hashable {
        case setting
        case accountInfo
        case changeGenderOrAge
        case blockUserList
        case withdrawFlow
        case profilePublic
        case notificationSetting
        case completionNotificationList
        case hiatusReturnNotificationList
    }

    @State private var dataSource: DataSource = .mock
    @State private var pushAuthorizationScenario: PushAuthorizationScenario = .authorized
    @State private var path = NavigationPath()
    /// 성별/나이 변경 화면이 저장 성공으로 dismiss된 뒤, 돌아온 계정정보 화면에서 띄운다(App이 대신
    /// 띄워야 하는 토스트 — `SettingFeature/CLAUDE.md`의 "저장됨" 토스트 이관 참고).
    @State private var isChangeSavedToastPresented = false
    /// 프로필 공개 설정 화면이 저장 성공으로 dismiss된 뒤, 돌아온 설정 목록 화면에서 띄운다.
    @State private var isVisibilityChangedToastPresented = false
    @State private var visibilityChangedToastType: WSSToastType = .changePublic
    /// Mock 모드 차단 목록의 인메모리 상태. 화면을 다시 열어도 차단 해제 결과가 유지되도록 세션 동안 보관한다.
    @State private var mockBlockedUsersStore = DemoBlockedUsersStore()
    /// Mock 모드 프로필 공개 설정의 인메모리 상태.
    @State private var mockProfileVisibilityStore = DemoProfileVisibilityStore()
    /// Mock 모드 알림 설정의 인메모리 상태.
    @State private var mockPushPreferenceStore = DemoPushPreferenceStore()
    /// Mock 모드 완결/휴재복귀 알림 구독 목록의 인메모리 상태.
    @State private var mockNovelNotificationStore = DemoNovelNotificationSubscriptionsStore()

    private let consoleLogger = ConsoleLogger()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 24) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker("푸시 권한 시나리오", selection: $pushAuthorizationScenario) {
                    ForEach(PushAuthorizationScenario.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Button("설정 목록 열기") {
                    path.append(Destination.setting)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("WSS Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .setting:
                    settingView
                case .accountInfo:
                    accountInfoView
                case .changeGenderOrAge:
                    changeGenderOrAgeView
                case .blockUserList:
                    blockUserListView
                case .withdrawFlow:
                    withdrawFlowView
                case .profilePublic:
                    profilePublicView
                case .notificationSetting:
                    notificationSettingView
                case .completionNotificationList:
                    completionNotificationListView
                case .hiatusReturnNotificationList:
                    hiatusReturnNotificationListView
                }
            }
            .showWSSToast(isPresented: $isChangeSavedToastPresented, type: .changeInfo)
            .showWSSToast(isPresented: $isVisibilityChangedToastPresented, type: visibilityChangedToastType)
        }
    }

    // MARK: - 화면 조립 (Mock ↔ 실서버)

    /// 설정 목록 자체는 UseCase가 필요 없어졌다(#201) — 하위 화면을 더 이상 여기서 조립하지 않고
    /// 메뉴 탭 콜백만 올리므로, `pushAuthorizationChecker`(서버와 무관, iOS 시스템 권한) 하나만
    /// 있으면 된다. `dataSource`(Mock/실서버)는 이 화면엔 영향이 없다.
    private var settingView: some View {
        SettingFeatureFactory.makeView(
            pushAuthorizationChecker: DemoPushAuthorizationChecker(status: pushAuthorizationScenario.status),
            logger: consoleLogger,
            onAccountInfoTapped: { path.append(Destination.accountInfo) },
            onProfilePublicTapped: { path.append(Destination.profilePublic) },
            onNotificationSettingTapped: { path.append(Destination.notificationSetting) }
        )
    }

    @ViewBuilder
    private var accountInfoView: some View {
        switch dataSource {
        case .mock:
            SettingFeatureFactory.makeAccountInfoView(
                loadAccountInfoDraftUseCase: DemoLoadAccountInfoDraftUseCase(),
                logoutUseCase: DemoLogoutUseCase(),
                logger: consoleLogger,
                onLogoutSuccess: { path = NavigationPath() },
                onChangeGenderOrAgeTapped: { path.append(Destination.changeGenderOrAge) },
                onBlockUserListTapped: { path.append(Destination.blockUserList) },
                onWithdrawTapped: { path.append(Destination.withdrawFlow) }
            )
        case .live:
            let dependencies = makeLiveDependencies()
            SettingFeatureFactory.makeAccountInfoView(
                loadAccountInfoDraftUseCase: DefaultLoadAccountInfoDraftUseCase(repository: dependencies.profileRepository),
                logoutUseCase: DefaultLogoutUseCase(authRepository: dependencies.authRepository),
                logger: consoleLogger,
                onLogoutSuccess: { path = NavigationPath() },
                onChangeGenderOrAgeTapped: { path.append(Destination.changeGenderOrAge) },
                onBlockUserListTapped: { path.append(Destination.blockUserList) },
                onWithdrawTapped: { path.append(Destination.withdrawFlow) }
            )
        }
    }

    @ViewBuilder
    private var changeGenderOrAgeView: some View {
        switch dataSource {
        case .mock:
            SettingFeatureFactory.makeChangeGenderOrAgeView(
                loadLocalGenderAndBirthUseCase: DemoLoadLocalGenderAndBirthUseCase(),
                saveAccountInfoDraftUseCase: DemoSaveAccountInfoDraftUseCase(),
                logger: consoleLogger,
                onSaveSuccess: { isChangeSavedToastPresented = true }
            )
        case .live:
            let dependencies = makeLiveDependencies()
            SettingFeatureFactory.makeChangeGenderOrAgeView(
                loadLocalGenderAndBirthUseCase: DefaultLoadLocalGenderAndBirthUseCase(repository: dependencies.profileRepository),
                saveAccountInfoDraftUseCase: DefaultSaveAccountInfoDraftUseCase(repository: dependencies.profileRepository),
                logger: consoleLogger,
                onSaveSuccess: { isChangeSavedToastPresented = true }
            )
        }
    }

    @ViewBuilder
    private var blockUserListView: some View {
        switch dataSource {
        case .mock:
            SettingFeatureFactory.makeBlockUserListView(
                loadBlockedUsersUseCase: DemoLoadBlockedUsersUseCase(store: mockBlockedUsersStore),
                unblockUserUseCase: DemoUnblockUserUseCase(store: mockBlockedUsersStore),
                logger: consoleLogger
            )
        case .live:
            let dependencies = makeLiveDependencies()
            SettingFeatureFactory.makeBlockUserListView(
                loadBlockedUsersUseCase: DefaultLoadBlockedUsersUseCase(repository: dependencies.socialRepository),
                unblockUserUseCase: DefaultUnblockUserUseCase(repository: dependencies.socialRepository),
                logger: consoleLogger
            )
        }
    }

    /// "확인→사유" 2단계는 `WithdrawFlowView` 안에서 여전히 로컬로 진행된다(사용자 확정) — App은
    /// 이 진입점 하나만 push하면 된다.
    @ViewBuilder
    private var withdrawFlowView: some View {
        switch dataSource {
        case .mock:
            SettingFeatureFactory.makeWithdrawFlowView(
                loadRegisteredNovelStatsUseCase: DemoLoadRegisteredNovelStatsUseCase(),
                withdrawUseCase: DemoWithdrawUseCase(),
                logger: consoleLogger,
                onWithdrawSuccess: { path = NavigationPath() }
            )
        case .live:
            let dependencies = makeLiveDependencies()
            SettingFeatureFactory.makeWithdrawFlowView(
                loadRegisteredNovelStatsUseCase: DefaultLoadRegisteredNovelStatsUseCase(novelRepository: dependencies.novelRepository),
                withdrawUseCase: DefaultWithdrawUseCase(repository: dependencies.authRepository),
                logger: consoleLogger,
                onWithdrawSuccess: { path = NavigationPath() }
            )
        }
    }

    @ViewBuilder
    private var profilePublicView: some View {
        switch dataSource {
        case .mock:
            SettingFeatureFactory.makeProfilePublicView(
                loadProfileVisibilityUseCase: DemoLoadProfileVisibilityUseCase(store: mockProfileVisibilityStore),
                updateProfileVisibilityUseCase: DemoUpdateProfileVisibilityUseCase(store: mockProfileVisibilityStore),
                logger: consoleLogger,
                onSaveSuccess: showVisibilityChangedToast
            )
        case .live:
            let dependencies = makeLiveDependencies()
            SettingFeatureFactory.makeProfilePublicView(
                loadProfileVisibilityUseCase: DefaultLoadProfileVisibilityUseCase(repository: dependencies.profileRepository),
                updateProfileVisibilityUseCase: DefaultUpdateProfileVisibilityUseCase(repository: dependencies.profileRepository),
                logger: consoleLogger,
                onSaveSuccess: showVisibilityChangedToast
            )
        }
    }

    @ViewBuilder
    private var notificationSettingView: some View {
        switch dataSource {
        case .mock:
            SettingFeatureFactory.makeNotificationSettingView(
                loadPushPreferenceUseCase: DemoLoadPushPreferenceUseCase(store: mockPushPreferenceStore),
                updatePushPreferenceUseCase: DemoUpdatePushPreferenceUseCase(store: mockPushPreferenceStore),
                logger: consoleLogger,
                onCompletionListTapped: { path.append(Destination.completionNotificationList) },
                onHiatusReturnListTapped: { path.append(Destination.hiatusReturnNotificationList) }
            )
        case .live:
            let dependencies = makeLiveDependencies()
            SettingFeatureFactory.makeNotificationSettingView(
                loadPushPreferenceUseCase: DefaultLoadPushPreferenceUseCase(repository: dependencies.pushSettingRepository),
                updatePushPreferenceUseCase: DefaultUpdatePushPreferenceUseCase(repository: dependencies.pushSettingRepository),
                logger: consoleLogger,
                onCompletionListTapped: { path.append(Destination.completionNotificationList) },
                onHiatusReturnListTapped: { path.append(Destination.hiatusReturnNotificationList) }
            )
        }
    }

    @ViewBuilder
    private var completionNotificationListView: some View {
        switch dataSource {
        case .mock:
            SettingFeatureFactory.makeCompletionNotificationListView(
                loadNovelNotificationSubscriptionsUseCase: DemoLoadNovelNotificationSubscriptionsUseCase(store: mockNovelNotificationStore),
                deleteNovelNotificationSubscriptionsUseCase: DemoDeleteNovelNotificationSubscriptionsUseCase(store: mockNovelNotificationStore),
                logger: consoleLogger,
                onBrowseNovels: logBrowseNovels
            )
        case .live:
            let dependencies = makeLiveDependencies()
            SettingFeatureFactory.makeCompletionNotificationListView(
                loadNovelNotificationSubscriptionsUseCase: DefaultLoadNovelNotificationSubscriptionsUseCase(repository: dependencies.novelNotificationRepository),
                deleteNovelNotificationSubscriptionsUseCase: DefaultDeleteNovelNotificationSubscriptionsUseCase(repository: dependencies.novelNotificationRepository),
                logger: consoleLogger,
                onBrowseNovels: logBrowseNovels
            )
        }
    }

    @ViewBuilder
    private var hiatusReturnNotificationListView: some View {
        switch dataSource {
        case .mock:
            SettingFeatureFactory.makeHiatusReturnNotificationListView(
                loadNovelNotificationSubscriptionsUseCase: DemoLoadNovelNotificationSubscriptionsUseCase(store: mockNovelNotificationStore),
                deleteNovelNotificationSubscriptionsUseCase: DemoDeleteNovelNotificationSubscriptionsUseCase(store: mockNovelNotificationStore),
                logger: consoleLogger,
                onBrowseNovels: logBrowseNovels
            )
        case .live:
            let dependencies = makeLiveDependencies()
            SettingFeatureFactory.makeHiatusReturnNotificationListView(
                loadNovelNotificationSubscriptionsUseCase: DefaultLoadNovelNotificationSubscriptionsUseCase(repository: dependencies.novelNotificationRepository),
                deleteNovelNotificationSubscriptionsUseCase: DefaultDeleteNovelNotificationSubscriptionsUseCase(repository: dependencies.novelNotificationRepository),
                logger: consoleLogger,
                onBrowseNovels: logBrowseNovels
            )
        }
    }

    // MARK: - 콜백

    private func showVisibilityChangedToast(isPublic: Bool) {
        visibilityChangedToastType = isPublic ? .changePublic : .changePrivate
        isVisibilityChangedToastPresented = true
    }

    private func logBrowseNovels() {
        consoleLogger.info("[디버그] 작품 둘러보기 → 검색 화면 이동(App 라우팅 미구현)")
    }

    // MARK: - 실서버 조립

    /// 화면마다 새로 호출한다(다른 Demo 앱들과 동일 관례 — client/TokenStore는 화면 진입마다 새로
    /// 만들어도 무방하다, `App/CLAUDE.md`의 DI 절 참고). 6개 Repository를 여러 화면이 공유하는
    /// 구조라 튜플로 한 번에 묶어 반환한다.
    @MainActor
    private func makeLiveDependencies() -> (
        client: NetworkingClient,
        profileRepository: ProfileRepository,
        socialRepository: SocialRepository,
        pushSettingRepository: PushSettingRepository,
        novelNotificationRepository: NovelNotificationRepository,
        authRepository: AuthRepository,
        novelRepository: NovelRepository
    ) {
        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )
        let profileRepository = ProfileDataFactory.makeProfileRepository(
            client: client,
            localStorage: UserDefaultsStorage(),
            logger: DataLogger(moduleName: "ProfileData", underlying: consoleLogger)
        )
        let socialRepository = SocialDataFactory.makeSocialRepository(
            client: client,
            logger: DataLogger(moduleName: "SocialData", underlying: consoleLogger)
        )
        let pushSettingRepository = NotificationDataFactory.makePushSettingRepository(
            client: client,
            logger: DataLogger(moduleName: "NotificationData", underlying: consoleLogger)
        )
        let novelNotificationRepository = NotificationDataFactory.makeNovelNotificationRepository(
            client: client,
            logger: DataLogger(moduleName: "NotificationData", underlying: consoleLogger)
        )
        let authTokenStore = DemoAuthTokenStore()
        // 실서버 조립이지만 로그인 플로우가 없어 refreshToken이 비어있다 — 로그아웃/탈퇴 데모가
        // 항상 "refreshToken 없음"으로 막히지 않도록 더미 값을 미리 심어둔다.
        try? authTokenStore.saveRefreshToken("demo-refresh-token")
        let deviceIdentifierStore = DefaultDeviceIdentifierStore()
        // deviceIdentifier도 실기기 등록 플로우가 없으면 Keychain에 값이 없어 같은 이유로 막힌다.
        try? deviceIdentifierStore.saveDeviceIdentifier("demo-device-identifier")
        let authRepository = AuthDataFactory.makeRepository(
            client: client,
            tokenStore: authTokenStore,
            deviceIdentifierStore: deviceIdentifierStore,
            logger: DataLogger(moduleName: "AuthData", underlying: consoleLogger)
        )
        let novelRepository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: UserDefaultsStorage(),
            logger: DataLogger(moduleName: "NovelData", underlying: consoleLogger)
        )
        return (client, profileRepository, socialRepository, pushSettingRepository, novelNotificationRepository, authRepository, novelRepository)
    }
}

// MARK: - Demo UseCases (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요).

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

private struct DemoLoadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase {
    func execute() async throws(RepositoryError) -> AccountInfoDraft {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return AccountInfoDraft(email: nil, gender: .female, birth: try! BirthYear(2001))
    }
}

private struct DemoSaveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase {
    func execute(_ info: AccountInfoDraft) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 800_000_000)
    }
}

private struct DemoLoadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase {
    func execute() async throws(RepositoryError) -> AccountInfoDraft {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return AccountInfoDraft(email: "wss@websoso.kr", gender: .female, birth: try! BirthYear(2001))
    }
}

/// Mock 차단 목록의 인메모리 상태. 화면 재진입/차단 해제 결과가 데모 세션 동안 유지되도록 참조 타입으로 둔다.
@MainActor
private final class DemoBlockedUsersStore {
    private(set) var blockedUsers: [BlockedUser] = [
        BlockedUser(
            blockID: BlockID(1),
            userID: UserID(101),
            nickname: "구리스",
            profileImageURL: URL(string: "https://i.pinimg.com/736x/97/e1/61/97e1612b1e1bab88df11c62111a09ddc.jpg")
        ),
        BlockedUser(blockID: BlockID(2), userID: UserID(102), nickname: "웹소소", profileImageURL: nil)
    ]

    func unblock(_ id: BlockID) {
        blockedUsers.removeAll { $0.blockID == id }
    }
}

private struct DemoLoadBlockedUsersUseCase: LoadBlockedUsersUseCase {
    let store: DemoBlockedUsersStore

    func execute() async throws(RepositoryError) -> [BlockedUser] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return await store.blockedUsers
    }
}

private struct DemoUnblockUserUseCase: UnblockUserUseCase {
    let store: DemoBlockedUsersStore

    func execute(id: BlockID) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 500_000_000)
        await store.unblock(id)
    }
}

/// Mock 프로필 공개 설정의 인메모리 상태. 화면 재진입 시에도 마지막으로 저장한 값이 유지되도록 참조 타입으로 둔다.
@MainActor
private final class DemoProfileVisibilityStore {
    private(set) var isPublic = true

    func update(_ isPublic: Bool) {
        self.isPublic = isPublic
    }
}

private struct DemoLoadProfileVisibilityUseCase: LoadProfileVisibilityUseCase {
    let store: DemoProfileVisibilityStore

    func execute() async throws(RepositoryError) -> ProfileVisibility {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return await ProfileVisibility(isPublic: store.isPublic)
    }
}

private struct DemoUpdateProfileVisibilityUseCase: UpdateProfileVisibilityUseCase {
    let store: DemoProfileVisibilityStore

    func execute(_ visibility: ProfileVisibility) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 800_000_000)
        await store.update(visibility.isPublic)
    }
}

/// Mock 알림 설정의 인메모리 상태. 화면 재진입 시에도 마지막으로 저장한 값이 유지되도록 참조 타입으로 둔다.
@MainActor
private final class DemoPushPreferenceStore {
    private(set) var isEnabled = true

    func update(_ isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}

private struct DemoLoadPushPreferenceUseCase: LoadPushPreferenceUseCase {
    let store: DemoPushPreferenceStore

    func execute() async throws(RepositoryError) -> PushPreference {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return await PushPreference(isEnabled: store.isEnabled)
    }
}

private struct DemoUpdatePushPreferenceUseCase: UpdatePushPreferenceUseCase {
    let store: DemoPushPreferenceStore

    func execute(pushPreference: PushPreference) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 800_000_000)
        await store.update(pushPreference.isEnabled)
    }
}

/// Mock 완결/휴재복귀 알림 구독 목록의 인메모리 상태. 목록이 짧아 커서 페이지네이션 없이 한 번에 다 보여준다.
@MainActor
private final class DemoNovelNotificationSubscriptionsStore {
    private(set) var completionSubscriptions: [NovelNotificationSubscription]
    private(set) var hiatusReturnSubscriptions: [NovelNotificationSubscription]

    init() {
        completionSubscriptions = (1...7).map { index in
            NovelNotificationSubscription(
                id: SubscriptionID(index),
                novelID: NovelID(index),
                novelTitle: "완결 알림 작품 \(index)",
                novelThumbnailImage: nil,
                novelAuthor: "작가 \(index)",
                registeredDateText: String(format: "2026.08.%02d", index)
            )
        }
        hiatusReturnSubscriptions = (1...3).map { index in
            NovelNotificationSubscription(
                id: SubscriptionID(100 + index),
                novelID: NovelID(100 + index),
                novelTitle: "휴재 복귀 알림 작품 \(index)",
                novelThumbnailImage: nil,
                novelAuthor: "작가 \(index)",
                registeredDateText: String(format: "2026.08.%02d", index)
            )
        }
    }

    func subscriptions(for type: NovelNotificationType) -> [NovelNotificationSubscription] {
        switch type {
        case .completion:   completionSubscriptions
        case .hiatusReturn: hiatusReturnSubscriptions
        }
    }

    func delete(type: NovelNotificationType, novelIDs: [NovelID]) {
        switch type {
        case .completion:   completionSubscriptions.removeAll { novelIDs.contains($0.novelID) }
        case .hiatusReturn: hiatusReturnSubscriptions.removeAll { novelIDs.contains($0.novelID) }
        }
    }
}

private struct DemoLoadNovelNotificationSubscriptionsUseCase: LoadNovelNotificationSubscriptionsUseCase {
    let store: DemoNovelNotificationSubscriptionsStore

    func execute(
        type: NovelNotificationType,
        lastSubscriptionID: SubscriptionID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNovelNotificationSubscriptions {
        try? await Task.sleep(nanoseconds: 500_000_000)
        let subscriptions = await store.subscriptions(for: type)
        return PagedNovelNotificationSubscriptions(subscriptions: subscriptions, isLoadable: false, nextSubscriptionID: nil)
    }
}

private struct DemoDeleteNovelNotificationSubscriptionsUseCase: DeleteNovelNotificationSubscriptionsUseCase {
    let store: DemoNovelNotificationSubscriptionsStore

    func execute(type: NovelNotificationType, novelIDs: [NovelID]) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 500_000_000)
        await store.delete(type: type, novelIDs: novelIDs)
    }
}

private struct DemoWithdrawUseCase: WithdrawUseCase {
    func execute(draft: WithdrawalReasonDraft) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 800_000_000)
    }
}

private struct DemoLogoutUseCase: LogoutUseCase {
    func execute() async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

private struct DemoLoadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase {
    func execute() async throws(RepositoryError) -> RegisteredNovelStats {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return RegisteredNovelStats(interest: 4, watching: 30, watched: 1312, quit: 24)
    }
}

/// 실서버 회원탈퇴 데모용 인메모리 TokenStore. 로그인 플로우 없이 `NetworkingConfig.testApiKey`로
/// 인증 헤더를 채운다(다른 실서버 조립에서 쓰는 `DemoSessionTokenStore`와 동일한 관례).
private final class DemoAuthTokenStore: TokenStore {
    private var refresh: String?

    func saveAccessToken(_ token: String) throws {}
    func saveRefreshToken(_ token: String) throws { refresh = token }
    func accessToken() throws -> String? { NetworkingConfig.testApiKey }
    func refreshToken() throws -> String? { refresh }
    func clearTokens() throws { refresh = nil }
}
