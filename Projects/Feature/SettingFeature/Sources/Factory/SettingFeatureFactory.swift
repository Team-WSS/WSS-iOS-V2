//
//  SettingFeatureFactory.swift
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

/// 모듈의 public 진입점 — 화면마다 `make<Screen>View`로 짓는다(#201부터, **화면 간 이동은 전부 App이
/// 조립한다** — 예외는 성별/나이 변경 화면의 생년 선택 시트뿐, 그건 그 화면 자신의 draft를 채우는
/// 로컬 값 선택기라서 그대로 둔다). `makeWithdrawFlowView`만 예외로 "확인→사유" 2단계를 여전히 내부적으로
/// 로컬 push한다(사용자 확정) — App은 이 진입점 하나만 조립하면 된다.
public enum SettingFeatureFactory {

    /// 설정 목록 진입점. 하위 화면(계정정보/프로필 공개 설정/알림 설정)은 여기서 만들지 않는다 —
    /// 메뉴 탭 콜백만 올리고, 실제 조립은 호출자(App)가 각 `make<Screen>View`로 한다.
    @MainActor
    public static func makeView(
        pushAuthorizationChecker: PushAuthorizationChecker,
        logger: Logger? = nil,
        onAccountInfoTapped: @escaping () -> Void = {},
        onProfilePublicTapped: @escaping () -> Void = {},
        onNotificationSettingTapped: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = SettingViewModel(pushAuthorizationChecker: pushAuthorizationChecker, logger: logger)
        return SettingView(
            viewModel: viewModel,
            onAccountInfoTapped: onAccountInfoTapped,
            onProfilePublicTapped: onProfilePublicTapped,
            onNotificationSettingTapped: onNotificationSettingTapped
        )
    }

    /// 계정정보 진입점. 하위 화면(성별/나이 변경·차단유저 목록·회원탈퇴)도 여기서 만들지 않는다 —
    /// 메뉴 탭 콜백만 올리고, 실제 조립은 호출자(App)가 한다.
    @MainActor
    public static func makeAccountInfoView(
        loadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase,
        logoutUseCase: LogoutUseCase,
        logger: Logger? = nil,
        onLogoutSuccess: @escaping () -> Void = {},
        onChangeGenderOrAgeTapped: @escaping () -> Void = {},
        onBlockUserListTapped: @escaping () -> Void = {},
        onWithdrawTapped: @escaping () -> Void = {},
        onAuthenticationRequired: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = SettingAccountInfoViewModel(
            loadAccountInfoDraftUseCase: loadAccountInfoDraftUseCase,
            logoutUseCase: logoutUseCase,
            logger: logger
        )
        return SettingAccountInfoView(
            viewModel: viewModel,
            onLogoutSuccess: onLogoutSuccess,
            onChangeGenderOrAgeTapped: onChangeGenderOrAgeTapped,
            onBlockUserListTapped: onBlockUserListTapped,
            onWithdrawTapped: onWithdrawTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    @MainActor
    public static func makeChangeGenderOrAgeView(
        loadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase,
        saveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase,
        logger: Logger? = nil,
        onSaveSuccess: @escaping () -> Void = {},
        onAuthenticationRequired: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = SettingChangeGenderOrAgeViewModel(
            loadLocalGenderAndBirthUseCase: loadLocalGenderAndBirthUseCase,
            saveAccountInfoDraftUseCase: saveAccountInfoDraftUseCase,
            logger: logger
        )
        return SettingChangeGenderOrAgeView(
            viewModel: viewModel,
            onSaveSuccess: onSaveSuccess,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    @MainActor
    public static func makeBlockUserListView(
        loadBlockedUsersUseCase: LoadBlockedUsersUseCase,
        unblockUserUseCase: UnblockUserUseCase,
        logger: Logger? = nil,
        onAuthenticationRequired: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = SettingBlockUserListViewModel(
            loadBlockedUsersUseCase: loadBlockedUsersUseCase,
            unblockUserUseCase: unblockUserUseCase,
            logger: logger
        )
        return SettingBlockUserListView(viewModel: viewModel, onAuthenticationRequired: onAuthenticationRequired)
    }

    @MainActor
    public static func makeWithdrawConfirmView(
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        logger: Logger? = nil,
        onConfirm: @escaping () -> Void = {},
        onAuthenticationRequired: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = WithdrawConfirmViewModel(
            loadRegisteredNovelStatsUseCase: loadRegisteredNovelStatsUseCase,
            logger: logger
        )
        return WithdrawConfirmView(
            viewModel: viewModel,
            onConfirm: onConfirm,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// `WithdrawConfirmView` → `WithdrawReasonView`를 하나의 push 체인으로 묶는다.
    /// `SettingAccountInfoView`가 두 destination을 각각 bool로 들면 Confirm 확인 시 두 bool이 동시에 true가 되어
    /// 스택 push가 깨지므로, Reason의 트리거를 `WithdrawFlowView`(Confirm이 이미 push된 지점)로 옮겨 둔다.
    @MainActor
    public static func makeWithdrawFlowView(
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        withdrawUseCase: WithdrawUseCase,
        logger: Logger? = nil,
        onWithdrawSuccess: @escaping () -> Void = {},
        onAuthenticationRequired: @escaping () -> Void = {}
    ) -> some View {
        WithdrawFlowView(
            loadRegisteredNovelStatsUseCase: loadRegisteredNovelStatsUseCase,
            withdrawUseCase: withdrawUseCase,
            logger: logger,
            onWithdrawSuccess: onWithdrawSuccess,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    @MainActor
    public static func makeWithdrawReasonView(
        withdrawUseCase: WithdrawUseCase,
        logger: Logger? = nil,
        onWithdrawSuccess: @escaping () -> Void = {},
        onAuthenticationRequired: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = WithdrawReasonViewModel(
            withdrawUseCase: withdrawUseCase,
            logger: logger
        )
        return WithdrawReasonView(
            viewModel: viewModel,
            onWithdrawSuccess: onWithdrawSuccess,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    @MainActor
    public static func makeProfilePublicView(
        loadProfileVisibilityUseCase: LoadProfileVisibilityUseCase,
        updateProfileVisibilityUseCase: UpdateProfileVisibilityUseCase,
        logger: Logger? = nil,
        onSaveSuccess: @escaping (Bool) -> Void = { _ in },
        onAuthenticationRequired: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = SettingProfilePublicViewModel(
            loadProfileVisibilityUseCase: loadProfileVisibilityUseCase,
            updateProfileVisibilityUseCase: updateProfileVisibilityUseCase,
            logger: logger
        )
        return SettingProfilePublicView(
            viewModel: viewModel,
            onSaveSuccess: onSaveSuccess,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// 알림 설정 진입점. 하위 화면(완결/휴재복귀 알림 목록)도 여기서 만들지 않는다 — row 탭 콜백만
    /// 올리고, 실제 조립은 호출자(App)가 `makeCompletionNotificationListView`/`makeHiatusReturnNotificationListView`로 한다.
    @MainActor
    public static func makeNotificationSettingView(
        loadPushPreferenceUseCase: LoadPushPreferenceUseCase,
        updatePushPreferenceUseCase: UpdatePushPreferenceUseCase,
        logger: Logger? = nil,
        onCompletionListTapped: @escaping () -> Void = {},
        onHiatusReturnListTapped: @escaping () -> Void = {},
        onAuthenticationRequired: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = NotificationSettingViewModel(
            loadPushPreferenceUseCase: loadPushPreferenceUseCase,
            updatePushPreferenceUseCase: updatePushPreferenceUseCase,
            logger: logger
        )
        return NotificationSettingView(
            viewModel: viewModel,
            onCompletionListTapped: onCompletionListTapped,
            onHiatusReturnListTapped: onHiatusReturnListTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// 완결/휴재복귀 알림 목록은 화면 구조가 완전히 같아(#188) `type`만 달리해 같은 `NovelNotificationListView`를 재사용한다.
    @MainActor
    public static func makeCompletionNotificationListView(
        loadNovelNotificationSubscriptionsUseCase: LoadNovelNotificationSubscriptionsUseCase,
        deleteNovelNotificationSubscriptionsUseCase: DeleteNovelNotificationSubscriptionsUseCase,
        logger: Logger? = nil,
        onBrowseNovels: @escaping () -> Void = {},
        onAuthenticationRequired: @escaping () -> Void = {}
    ) -> some View {
        makeNovelNotificationListView(
            type: .completion,
            loadNovelNotificationSubscriptionsUseCase: loadNovelNotificationSubscriptionsUseCase,
            deleteNovelNotificationSubscriptionsUseCase: deleteNovelNotificationSubscriptionsUseCase,
            logger: logger,
            onBrowseNovels: onBrowseNovels,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    @MainActor
    public static func makeHiatusReturnNotificationListView(
        loadNovelNotificationSubscriptionsUseCase: LoadNovelNotificationSubscriptionsUseCase,
        deleteNovelNotificationSubscriptionsUseCase: DeleteNovelNotificationSubscriptionsUseCase,
        logger: Logger? = nil,
        onBrowseNovels: @escaping () -> Void = {},
        onAuthenticationRequired: @escaping () -> Void = {}
    ) -> some View {
        makeNovelNotificationListView(
            type: .hiatusReturn,
            loadNovelNotificationSubscriptionsUseCase: loadNovelNotificationSubscriptionsUseCase,
            deleteNovelNotificationSubscriptionsUseCase: deleteNovelNotificationSubscriptionsUseCase,
            logger: logger,
            onBrowseNovels: onBrowseNovels,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    @MainActor
    private static func makeNovelNotificationListView(
        type: NovelNotificationType,
        loadNovelNotificationSubscriptionsUseCase: LoadNovelNotificationSubscriptionsUseCase,
        deleteNovelNotificationSubscriptionsUseCase: DeleteNovelNotificationSubscriptionsUseCase,
        logger: Logger?,
        onBrowseNovels: @escaping () -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        let viewModel = NovelNotificationListViewModel(
            type: type,
            loadSubscriptionsUseCase: loadNovelNotificationSubscriptionsUseCase,
            deleteSubscriptionsUseCase: deleteNovelNotificationSubscriptionsUseCase,
            logger: logger
        )
        return NovelNotificationListView(
            title: type.novelNotificationListTitle,
            viewModel: viewModel,
            onBrowseNovels: onBrowseNovels,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}

// MARK: - Presentation

/// `type`이 이미 화면을 정하므로(`makeCompletionNotificationListView`/`makeHiatusReturnNotificationListView`)
/// 제목을 별도 인자로 또 받지 않고 여기서 유도한다 — 둘이 어긋날 여지를 없앤다.
private extension NovelNotificationType {
    var novelNotificationListTitle: String {
        switch self {
        case .completion:   "완결 알림"
        case .hiatusReturn: "휴재 복귀 알림"
        }
    }
}
