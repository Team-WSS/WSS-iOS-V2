//
//  SettingFeatureDemoApp.swift
//  SettingFeatureDemo
//
//  Created by Seoyeon Choi on 7/15/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import SettingFeature
import SettingDomain
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
import DesignSystem
import WSSComponent

@main
struct SettingFeatureDemoApp: App {
    init() {
        DesignSystemFontFamily.registerAllCustomFonts()
        Self.seedLocalGenderAndBirthIfNeeded()
    }

    /// 실서버 모드는 userDefaults에 저장된 성별/출생연도를 읽어서 보여준다(서버 GET이 아님).
    /// 시뮬레이터엔 그 값이 없으므로, Demo 최초 실행 시 한 번 심어둔다(실제 값이 있으면 덮어쓰지 않음).
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

    @State private var dataSource: DataSource = .mock
    @State private var isSettingPresented = false
    /// Mock 모드 차단 목록의 인메모리 상태. 화면을 다시 열어도 차단 해제 결과가 유지되도록 세션 동안 보관한다.
    @State private var mockBlockedUsersStore = DemoBlockedUsersStore()
    /// Mock 모드 프로필 공개 설정의 인메모리 상태.
    @State private var mockProfileVisibilityStore = DemoProfileVisibilityStore()
    /// Mock 모드 알림 설정의 인메모리 상태.
    @State private var mockPushPreferenceStore = DemoPushPreferenceStore()

    private let consoleLogger = ConsoleLogger()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("데이터 소스", selection: $dataSource) {
                    ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                // 설정 목록 진입 후에는 계정정보/성별·나이 변경/차단유저 목록/프로필 공개 설정/알림 설정/회원탈퇴까지
                // 전부 SettingFeature 내부 실제 네비게이션으로 이동한다(개별 진입 버튼 없음).
                Button("설정 목록 열기") {
                    isSettingPresented = true
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("WSS Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isSettingPresented) {
                settingView
            }
        }
    }

    @ViewBuilder
    private var settingView: some View {
        switch dataSource {
        case .mock:
            SettingFactory.makeView(
                loadLocalGenderAndBirthUseCase: DemoLoadLocalGenderAndBirthUseCase(),
                saveAccountInfoDraftUseCase: DemoSaveAccountInfoDraftUseCase(),
                loadProfileVisibilityUseCase: DemoLoadProfileVisibilityUseCase(store: mockProfileVisibilityStore),
                updateProfileVisibilityUseCase: DemoUpdateProfileVisibilityUseCase(store: mockProfileVisibilityStore),
                loadBlockedUsersUseCase: DemoLoadBlockedUsersUseCase(store: mockBlockedUsersStore),
                unblockUserUseCase: DemoUnblockUserUseCase(store: mockBlockedUsersStore),
                loadPushPreferenceUseCase: DemoLoadPushPreferenceUseCase(store: mockPushPreferenceStore),
                updatePushPreferenceUseCase: DemoUpdatePushPreferenceUseCase(store: mockPushPreferenceStore),
                withdrawUseCase: DemoWithdrawUseCase(),
                logoutUseCase: DemoLogoutUseCase(),
                loadRegisteredNovelStatsUseCase: DemoLoadRegisteredNovelStatsUseCase(),
                logger: consoleLogger,
                onWithdrawSuccess: { isSettingPresented = false },
                onLogoutSuccess: { isSettingPresented = false }
            )
        case .live:
            makeLiveSettingView()
        }
    }

    // MARK: - 실서버 조립

    @MainActor
    private func makeLiveSettingView() -> some View {
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
            underlying: consoleLogger
        )
        let pushSettingRepository = NotificationDataFactory.makePushSettingRepository(
            client: client,
            logger: DataLogger(moduleName: "NotificationData", underlying: consoleLogger)
        )
        let authRepository = AuthDataFactory.makeRepository(
            client: client,
            tokenStore: DemoAuthTokenStore(),
            deviceIdentifierStore: DefaultDeviceIdentifierStore(),
            logger: DataLogger(moduleName: "AuthData", underlying: consoleLogger)
        )
        let novelRepository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: UserDefaultsStorage(),
            logger: DataLogger(moduleName: "NovelData", underlying: consoleLogger)
        )
        return SettingFactory.makeView(
            loadLocalGenderAndBirthUseCase: DefaultLoadLocalGenderAndBirthUseCase(repository: profileRepository),
            saveAccountInfoDraftUseCase: DefaultSaveAccountInfoDraftUseCase(repository: profileRepository),
            loadProfileVisibilityUseCase: DefaultLoadProfileVisibilityUseCase(repository: profileRepository),
            updateProfileVisibilityUseCase: DefaultUpdateProfileVisibilityUseCase(repository: profileRepository),
            loadBlockedUsersUseCase: DefaultLoadBlockedUsersUseCase(repository: socialRepository),
            unblockUserUseCase: DefaultUnblockUserUseCase(repository: socialRepository),
            loadPushPreferenceUseCase: DefaultLoadPushPreferenceUseCase(repository: pushSettingRepository),
            updatePushPreferenceUseCase: DefaultUpdatePushPreferenceUseCase(repository: pushSettingRepository),
            withdrawUseCase: DefaultWithdrawUseCase(repository: authRepository),
            logoutUseCase: DefaultLogoutUseCase(authRepository: authRepository),
            loadRegisteredNovelStatsUseCase: DefaultLoadRegisteredNovelStatsUseCase(novelRepository: novelRepository),
            logger: consoleLogger,
            onWithdrawSuccess: { isSettingPresented = false },
            onLogoutSuccess: { isSettingPresented = false }
        )
    }
}

// MARK: - Demo UseCases (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요).

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
