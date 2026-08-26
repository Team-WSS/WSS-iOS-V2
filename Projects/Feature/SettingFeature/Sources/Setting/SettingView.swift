//
//  SettingView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/15/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import ProfileDomain
import SocialDomain
import NotificationDomain
import AuthDomain
import NovelDomain
import DesignSystem
import WSSComponent
import Logger
import PushAuthorization

struct SettingView: View {

    @State private var viewModel: SettingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var isAccountInfoPresented = false
    @State private var isProfilePublicPresented = false
    @State private var isNotificationSettingPresented = false
    /// 프로필 공개 설정 화면이 저장 성공으로 dismiss된 뒤, 돌아온 이 화면에서 띄운다(공개/비공개에 따라 카피가 다르다).
    @State private var isVisibilityChangedToastPresented = false
    @State private var visibilityChangedToastType: WSSToastType = .changePublic

    private let logger: Logger?
    /// 탈퇴 성공 시 호출된다. 세션 종료(로그인 화면 전환 등)는 App(세션 관찰) 책임이라
    /// 이 화면들을 모두 지나 호출자에게 성공 신호만 전달한다.
    private let onWithdrawSuccess: () -> Void
    /// 로그아웃 성공 시 호출된다. 세션 종료(로그인 화면 전환 등)는 App(세션 관찰) 책임이라
    /// 이 화면들을 모두 지나 호출자에게 성공 신호만 전달한다.
    private let onLogoutSuccess: () -> Void

    // ProfileDomain
    private let loadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase
    private let saveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase
    private let loadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase
    private let loadProfileVisibilityUseCase: LoadProfileVisibilityUseCase
    private let updateProfileVisibilityUseCase: UpdateProfileVisibilityUseCase

    // SocialDomain
    private let loadBlockedUsersUseCase: LoadBlockedUsersUseCase
    private let unblockUserUseCase: UnblockUserUseCase

    // NotificationDomain
    private let loadPushPreferenceUseCase: LoadPushPreferenceUseCase
    private let updatePushPreferenceUseCase: UpdatePushPreferenceUseCase

    // AuthDomain
    private let withdrawUseCase: WithdrawUseCase
    private let logoutUseCase: LogoutUseCase

    // NovelDomain
    private let loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase

    init(
        viewModel: SettingViewModel,
        loadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase,
        saveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase,
        loadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase,
        loadProfileVisibilityUseCase: LoadProfileVisibilityUseCase,
        updateProfileVisibilityUseCase: UpdateProfileVisibilityUseCase,
        loadBlockedUsersUseCase: LoadBlockedUsersUseCase,
        unblockUserUseCase: UnblockUserUseCase,
        loadPushPreferenceUseCase: LoadPushPreferenceUseCase,
        updatePushPreferenceUseCase: UpdatePushPreferenceUseCase,
        withdrawUseCase: WithdrawUseCase,
        logoutUseCase: LogoutUseCase,
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        logger: Logger? = nil,
        onWithdrawSuccess: @escaping () -> Void = {},
        onLogoutSuccess: @escaping () -> Void = {}
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.loadLocalGenderAndBirthUseCase = loadLocalGenderAndBirthUseCase
        self.saveAccountInfoDraftUseCase = saveAccountInfoDraftUseCase
        self.loadAccountInfoDraftUseCase = loadAccountInfoDraftUseCase
        self.loadProfileVisibilityUseCase = loadProfileVisibilityUseCase
        self.updateProfileVisibilityUseCase = updateProfileVisibilityUseCase
        self.loadBlockedUsersUseCase = loadBlockedUsersUseCase
        self.unblockUserUseCase = unblockUserUseCase
        self.loadPushPreferenceUseCase = loadPushPreferenceUseCase
        self.updatePushPreferenceUseCase = updatePushPreferenceUseCase
        self.withdrawUseCase = withdrawUseCase
        self.logoutUseCase = logoutUseCase
        self.loadRegisteredNovelStatsUseCase = loadRegisteredNovelStatsUseCase
        self.logger = logger
        self.onWithdrawSuccess = onWithdrawSuccess
        self.onLogoutSuccess = onLogoutSuccess
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(SettingMenu.allCases, id: \.self) { menu in
                SettingMenuRow(title: menu.title) {
                    select(menu)
                }
            }

            Spacer()
        }
        .toolbar {
            toolbarContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .navigationDestination(isPresented: $isAccountInfoPresented) {
            SettingFactory.makeAccountInfoView(
                loadLocalGenderAndBirthUseCase: loadLocalGenderAndBirthUseCase,
                saveAccountInfoDraftUseCase: saveAccountInfoDraftUseCase,
                loadAccountInfoDraftUseCase: loadAccountInfoDraftUseCase,
                loadBlockedUsersUseCase: loadBlockedUsersUseCase,
                unblockUserUseCase: unblockUserUseCase,
                withdrawUseCase: withdrawUseCase,
                loadRegisteredNovelStatsUseCase: loadRegisteredNovelStatsUseCase,
                logoutUseCase: logoutUseCase,
                logger: logger,
                onWithdrawSuccess: onWithdrawSuccess,
                onLogoutSuccess: onLogoutSuccess
            )
        }
        .navigationDestination(isPresented: $isProfilePublicPresented) {
            SettingFactory.makeProfilePublicView(
                loadProfileVisibilityUseCase: loadProfileVisibilityUseCase,
                updateProfileVisibilityUseCase: updateProfileVisibilityUseCase,
                logger: logger,
                onSaveSuccess: { showVisibilityChangedToast(isPublic: $0) }
            )
        }
        .navigationDestination(isPresented: $isNotificationSettingPresented) {
            SettingFactory.makeNotificationSettingView(
                loadPushPreferenceUseCase: loadPushPreferenceUseCase,
                updatePushPreferenceUseCase: updatePushPreferenceUseCase,
                logger: logger
            )
        }
        .showWSSToast(isPresented: $isVisibilityChangedToastPresented, type: visibilityChangedToastType)
        .onChange(of: viewModel.state.shouldNavigateToNotificationSetting) { _, shouldNavigate in
            guard shouldNavigate else { return }
            viewModel.handle(.consumeNotificationSettingNavigation)
            isNotificationSettingPresented = true
        }
        .showWSSAlert(
            isPresented: pushAuthorizationAlertBinding,
            type: .setAppNotification,
            buttonActions: [
                { viewModel.handle(.dismissPushAuthorizationAlert) },  // "다음에 하기"
                {
                    viewModel.handle(.dismissPushAuthorizationAlert)
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }  // "설정하러 가기"
            ]
        )
    }

    private func select(_ menu: SettingMenu) {
        switch menu {
        case .accountInfo:
            isAccountInfoPresented = true
        case .profileVisibility:
            isProfilePublicPresented = true
        case .notification:
            viewModel.handle(.notificationMenuTapped)
        case .officialAccount, .inquiry, .privacyPolicy, .termsOfService:
            if let url = menu.externalURL { openURL(url) }
        }
    }

    private func showVisibilityChangedToast(isPublic: Bool) {
        visibilityChangedToastType = isPublic ? .changePublic : .changePrivate
        isVisibilityChangedToastPresented = true
    }

    private var pushAuthorizationAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isPushAuthorizationAlertPresented },
            set: { if !$0 { viewModel.handle(.dismissPushAuthorizationAlert) } }
        )
    }
}

// MARK: - Menu

extension SettingView {

    enum SettingMenu: CaseIterable {
        case accountInfo
        case profileVisibility
        case notification
        case officialAccount
        case inquiry
        case privacyPolicy
        case termsOfService

        var title: String {
            switch self {
            case .accountInfo:       "계정정보"
            case .profileVisibility: "프로필 공개 설정"
            case .notification:      "알림 설정"
            case .officialAccount:   "웹소소 공식 계정"
            case .inquiry:           "문의하기 & 의견 보내기"
            case .privacyPolicy:     "개인정보 처리방침"
            case .termsOfService:    "서비스 이용약관"
            }
        }

        /// 웹으로 나가는 딥링크. `accountInfo`/`profileVisibility`/`notification`은 앱 내부 화면 전환이라 nil.
        var externalURL: URL? {
            switch self {
            case .officialAccount:   AppURL.instaURL
            case .inquiry:           AppURL.errorReport
            case .privacyPolicy:     AppURL.privacyPolicy
            case .termsOfService:    AppURL.serviceAgreement
            case .accountInfo, .profileVisibility, .notification: nil
            }
        }
    }
}

// MARK: - Toolbar

private extension SettingView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 24, height: 24)
            }
        }

        ToolbarItem(placement: .principal) {
            Text("설정")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingView(
            viewModel: SettingViewModel(pushAuthorizationChecker: PreviewPushAuthorizationChecker()),
            loadLocalGenderAndBirthUseCase: PreviewLoadLocalGenderAndBirthUseCase(),
            saveAccountInfoDraftUseCase: PreviewSaveAccountInfoDraftUseCase(),
            loadAccountInfoDraftUseCase: PreviewLoadAccountInfoDraftUseCase(),
            loadProfileVisibilityUseCase: PreviewLoadProfileVisibilityUseCase(),
            updateProfileVisibilityUseCase: PreviewUpdateProfileVisibilityUseCase(),
            loadBlockedUsersUseCase: PreviewLoadBlockedUsersUseCase(),
            unblockUserUseCase: PreviewUnblockUserUseCase(),
            loadPushPreferenceUseCase: PreviewLoadPushPreferenceUseCase(),
            updatePushPreferenceUseCase: PreviewUpdatePushPreferenceUseCase(),
            withdrawUseCase: PreviewWithdrawUseCase(),
            logoutUseCase: PreviewLogoutUseCase(),
            loadRegisteredNovelStatsUseCase: PreviewLoadRegisteredNovelStatsUseCase()
        )
    }
}

private struct PreviewPushAuthorizationChecker: PushAuthorizationChecker {
    func authorizationStatus() async -> PushAuthorizationStatus { .authorized }
    func requestAuthorization() async -> Bool { true }
}

private struct PreviewLoadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase {
    func execute() async throws(RepositoryError) -> AccountInfoDraft {
        AccountInfoDraft(email: nil, gender: .female, birth: try! BirthYear(2001))
    }
}

private struct PreviewSaveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase {
    func execute(_ info: AccountInfoDraft) async throws(RepositoryError) {}
}

private struct PreviewLoadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase {
    func execute() async throws(RepositoryError) -> AccountInfoDraft {
        AccountInfoDraft(email: "wss@websoso.kr", gender: .female, birth: try! BirthYear(2001))
    }
}

private struct PreviewLoadProfileVisibilityUseCase: LoadProfileVisibilityUseCase {
    func execute() async throws(RepositoryError) -> ProfileVisibility {
        ProfileVisibility(isPublic: true)
    }
}

private struct PreviewUpdateProfileVisibilityUseCase: UpdateProfileVisibilityUseCase {
    func execute(_ visibility: ProfileVisibility) async throws(RepositoryError) {}
}

private struct PreviewLoadBlockedUsersUseCase: LoadBlockedUsersUseCase {
    func execute() async throws(RepositoryError) -> [BlockedUser] { [] }
}

private struct PreviewUnblockUserUseCase: UnblockUserUseCase {
    func execute(id: BlockID) async throws(RepositoryError) {}
}

private struct PreviewLoadPushPreferenceUseCase: LoadPushPreferenceUseCase {
    func execute() async throws(RepositoryError) -> PushPreference {
        PushPreference(isEnabled: true)
    }
}

private struct PreviewUpdatePushPreferenceUseCase: UpdatePushPreferenceUseCase {
    func execute(pushPreference: PushPreference) async throws(RepositoryError) {}
}

private struct PreviewWithdrawUseCase: WithdrawUseCase {
    func execute(draft: WithdrawalReasonDraft) async throws(RepositoryError) {}
}

private struct PreviewLogoutUseCase: LogoutUseCase {
    func execute() async throws(RepositoryError) {}
}

private struct PreviewLoadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase {
    func execute() async throws(RepositoryError) -> RegisteredNovelStats {
        RegisteredNovelStats(interest: 4, watching: 30, watched: 1312, quit: 24)
    }
}
