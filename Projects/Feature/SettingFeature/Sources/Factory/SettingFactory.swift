//
//  SettingFactory.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/15/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import ProfileDomain
import SocialDomain
import NotificationDomain
import AuthDomain
import NovelDomain
import Logger
import PushAuthorization

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 internal로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
public enum SettingFactory {

    /// 설정 진입점. `SettingView`(설정 목록) → `SettingAccountInfoView`(계정정보) → 성별/나이 변경·차단유저 목록,
    /// 그리고 `SettingView` → 프로필 공개 설정·알림 설정까지, 모듈 내부 화면 전환을 전부 포함한 하나의 플로우다.
    /// 하위 화면에 필요한 UseCase를 여기서 한 번에 주입받아 내부적으로 배선한다.
    @MainActor
    public static func makeView(
        // ProfileDomain
        loadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase,
        saveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase,
        loadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase,
        loadProfileVisibilityUseCase: LoadProfileVisibilityUseCase,
        updateProfileVisibilityUseCase: UpdateProfileVisibilityUseCase,
        // SocialDomain
        loadBlockedUsersUseCase: LoadBlockedUsersUseCase,
        unblockUserUseCase: UnblockUserUseCase,
        // NotificationDomain
        loadPushPreferenceUseCase: LoadPushPreferenceUseCase,
        updatePushPreferenceUseCase: UpdatePushPreferenceUseCase,
        // AuthDomain
        withdrawUseCase: WithdrawUseCase,
        logoutUseCase: LogoutUseCase,
        // NovelDomain
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        // PushAuthorization
        pushAuthorizationChecker: PushAuthorizationChecker,
        logger: Logger? = nil,
        onWithdrawSuccess: @escaping () -> Void = {},
        onLogoutSuccess: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = SettingViewModel(pushAuthorizationChecker: pushAuthorizationChecker, logger: logger)
        return SettingView(
            viewModel: viewModel,
            loadLocalGenderAndBirthUseCase: loadLocalGenderAndBirthUseCase,
            saveAccountInfoDraftUseCase: saveAccountInfoDraftUseCase,
            loadAccountInfoDraftUseCase: loadAccountInfoDraftUseCase,
            loadProfileVisibilityUseCase: loadProfileVisibilityUseCase,
            updateProfileVisibilityUseCase: updateProfileVisibilityUseCase,
            loadBlockedUsersUseCase: loadBlockedUsersUseCase,
            unblockUserUseCase: unblockUserUseCase,
            loadPushPreferenceUseCase: loadPushPreferenceUseCase,
            updatePushPreferenceUseCase: updatePushPreferenceUseCase,
            withdrawUseCase: withdrawUseCase,
            logoutUseCase: logoutUseCase,
            loadRegisteredNovelStatsUseCase: loadRegisteredNovelStatsUseCase,
            logger: logger,
            onWithdrawSuccess: onWithdrawSuccess,
            onLogoutSuccess: onLogoutSuccess
        )
    }

    @MainActor
    public static func makeAccountInfoView(
        loadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase,
        saveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase,
        loadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase,
        loadBlockedUsersUseCase: LoadBlockedUsersUseCase,
        unblockUserUseCase: UnblockUserUseCase,
        withdrawUseCase: WithdrawUseCase,
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        logoutUseCase: LogoutUseCase,
        logger: Logger? = nil,
        onWithdrawSuccess: @escaping () -> Void = {},
        onLogoutSuccess: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = SettingAccountInfoViewModel(
            loadAccountInfoDraftUseCase: loadAccountInfoDraftUseCase,
            logoutUseCase: logoutUseCase,
            logger: logger
        )
        return SettingAccountInfoView(
            viewModel: viewModel,
            loadLocalGenderAndBirthUseCase: loadLocalGenderAndBirthUseCase,
            saveAccountInfoDraftUseCase: saveAccountInfoDraftUseCase,
            loadBlockedUsersUseCase: loadBlockedUsersUseCase,
            unblockUserUseCase: unblockUserUseCase,
            withdrawUseCase: withdrawUseCase,
            loadRegisteredNovelStatsUseCase: loadRegisteredNovelStatsUseCase,
            logger: logger,
            onWithdrawSuccess: onWithdrawSuccess,
            onLogoutSuccess: onLogoutSuccess
        )
    }

    @MainActor
    public static func makeChangeGenderOrAgeView(
        loadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase,
        saveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase,
        logger: Logger? = nil,
        onSaveSuccess: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = SettingChangeGenderOrAgeViewModel(
            loadLocalGenderAndBirthUseCase: loadLocalGenderAndBirthUseCase,
            saveAccountInfoDraftUseCase: saveAccountInfoDraftUseCase,
            logger: logger
        )
        return SettingChangeGenderOrAgeView(viewModel: viewModel, onSaveSuccess: onSaveSuccess)
    }

    @MainActor
    public static func makeBlockUserListView(
        loadBlockedUsersUseCase: LoadBlockedUsersUseCase,
        unblockUserUseCase: UnblockUserUseCase,
        logger: Logger? = nil
    ) -> some View {
        let viewModel = SettingBlockUserListViewModel(
            loadBlockedUsersUseCase: loadBlockedUsersUseCase,
            unblockUserUseCase: unblockUserUseCase,
            logger: logger
        )
        return SettingBlockUserListView(viewModel: viewModel)
    }

    @MainActor
    public static func makeWithdrawConfirmView(
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        logger: Logger? = nil,
        onConfirm: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = WithdrawConfirmViewModel(
            loadRegisteredNovelStatsUseCase: loadRegisteredNovelStatsUseCase,
            logger: logger
        )
        return WithdrawConfirmView(viewModel: viewModel, onConfirm: onConfirm)
    }

    /// `WithdrawConfirmView` → `WithdrawReasonView`를 하나의 push 체인으로 묶는다.
    /// `SettingAccountInfoView`가 두 destination을 각각 bool로 들면 Confirm 확인 시 두 bool이 동시에 true가 되어
    /// 스택 push가 깨지므로, Reason의 트리거를 `WithdrawFlowView`(Confirm이 이미 push된 지점)로 옮겨 둔다.
    @MainActor
    public static func makeWithdrawFlowView(
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        withdrawUseCase: WithdrawUseCase,
        logger: Logger? = nil,
        onWithdrawSuccess: @escaping () -> Void = {}
    ) -> some View {
        WithdrawFlowView(
            loadRegisteredNovelStatsUseCase: loadRegisteredNovelStatsUseCase,
            withdrawUseCase: withdrawUseCase,
            logger: logger,
            onWithdrawSuccess: onWithdrawSuccess
        )
    }

    @MainActor
    public static func makeWithdrawReasonView(
        withdrawUseCase: WithdrawUseCase,
        logger: Logger? = nil,
        onWithdrawSuccess: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = WithdrawReasonViewModel(
            withdrawUseCase: withdrawUseCase,
            logger: logger
        )
        return WithdrawReasonView(viewModel: viewModel, onWithdrawSuccess: onWithdrawSuccess)
    }

    @MainActor
    public static func makeProfilePublicView(
        loadProfileVisibilityUseCase: LoadProfileVisibilityUseCase,
        updateProfileVisibilityUseCase: UpdateProfileVisibilityUseCase,
        logger: Logger? = nil,
        onSaveSuccess: @escaping (Bool) -> Void = { _ in }
    ) -> some View {
        let viewModel = SettingProfilePublicViewModel(
            loadProfileVisibilityUseCase: loadProfileVisibilityUseCase,
            updateProfileVisibilityUseCase: updateProfileVisibilityUseCase,
            logger: logger
        )
        return SettingProfilePublicView(viewModel: viewModel, onSaveSuccess: onSaveSuccess)
    }

    @MainActor
    public static func makeNotificationSettingView(
        loadPushPreferenceUseCase: LoadPushPreferenceUseCase,
        updatePushPreferenceUseCase: UpdatePushPreferenceUseCase,
        logger: Logger? = nil
    ) -> some View {
        let viewModel = NotificationSettingViewModel(
            loadPushPreferenceUseCase: loadPushPreferenceUseCase,
            updatePushPreferenceUseCase: updatePushPreferenceUseCase,
            logger: logger
        )
        return NotificationSettingView(viewModel: viewModel)
    }
}
