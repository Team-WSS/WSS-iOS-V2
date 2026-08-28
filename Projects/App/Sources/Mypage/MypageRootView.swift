//
//  MypageRootView.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import SettingFeature
import UserPageFeature
import BaseDomain
import AuthDomain
import CollectionDomain
import NotificationDomain
import NovelDomain
import ProfileDomain
import SocialDomain
import BaseData
import PushAuthorization
import WSSComponent

/// "My" 탭 콘텐츠. `MypageFeatureFactory`(`UserPageFeature` 모듈 소속 — 모듈명과 Factory 이름이 다르니 헷갈리지
/// 말 것)의 `makeView`를 붙이고, 프로필 편집(`makeEditView`)까지 실제로 push한다 — 화면 간 연결 조립은
/// 항상 App이 한다는 원칙(#196)에 따라, `MypageView`가 예전에 자체적으로 갖고 있던 내부
/// `navigationDestination`을 여기로 옮겼다.
///
/// **캐릭터 선택 시트(`makeCharacterEditSheet`)는 예외로 여전히 `MyPageEditView` 내부에 남아있다** —
/// 다른 화면으로의 이동이 아니라 그 화면 자신의 draft를 채우는 로컬 값 선택기라, App으로 올리면
/// 결과를 다시 그 화면 안으로 넣어주는 Binding 왕복이 필요해져 오히려 더 꼬인다(사용자 확정, #196).
///
/// 우측 상단 톱니바퀴 → 설정(`SettingFeatureFactory.makeView`)까지 push한다. 서재 블록 탭은 push가 아니라
/// **탭 전환**이라(`MainTabView.selectedTab`) `onLibraryTapped` 콜백으로 위로 흘려보낸다.
///
/// ⚠️ **`MypageFeatureFactory.makeView` 자체가 받는 `onAuthenticationRequired`는 없다** — 로드 401은
/// 여전히 조용히 빈 상태로 남는다(FeedFeature와 같은 사정, App 쪽에서 고칠 수 있는 부분이 아님). 다만
/// 여기서 push하는 **설정(`SettingFeatureFactory.makeView`)의 회원탈퇴/로그아웃 성공은 세션 자체를 끝내는
/// 이벤트**라, 다른 탭의 401 처리와 같은 경로(`onAuthenticationRequired` → 온보딩으로 라우팅)를 탄다.
struct MypageRootView: View {

    private enum Destination: Hashable {
        case edit
        case setting
    }

    let dependencies: AppDependencies
    /// 서재 블록 탭 → "서재" 탭으로 전환(`MainTabView`가 내려준다).
    let onLibraryTapped: () -> Void
    /// 설정의 회원탈퇴/로그아웃 성공, 또는 다른 탭과 동일한 401 만료 시 발화 — idempotent해야 한다
    /// (`MainTabView`/`HomeFeature`/`LibraryFeature`와 동일 계약).
    let onAuthenticationRequired: () -> Void

    @State private var path = NavigationPath()
    /// 프로필 편집 화면이 `onSaved`로 알려주면 세운다 — 그 화면이 아니라 복귀할 이 루트가 보여준다
    /// (편집 화면에서 sleep으로 노출 시간을 벌면 닫힘이 부자연스럽게 지연되므로, `UserPageFeature/CLAUDE.md` 참고).
    @State private var showProfileSavedToast = false

    /// 로그인 직후 `syncUserBasicInfo()`가 채워두는 로컬 캐시를 그대로 읽는다(`FeedDetailAssembly`와
    /// 동일 패턴) — "My" 탭은 로그인 후에만 진입하므로 정상 흐름에선 항상 채워져 있다.
    private var currentUserID: Int? {
        UserDefaultsStorage().get(.userID)
    }

    var body: some View {
        NavigationStack(path: $path) {
            MypageFeatureFactory.makeView(
                userID: UserID(currentUserID ?? 0),
                loadProfileUseCase: DefaultLoadProfileUseCase(profileRepository: dependencies.profileRepository),
                loadGenrePreferencesUseCase: DefaultLoadGenrePreferencesUseCase(
                    profileRepository: dependencies.profileRepository
                ),
                loadNovelPreferencesUseCase: DefaultLoadNovelPreferencesUseCase(
                    profileRepository: dependencies.profileRepository,
                    keywordRepository: dependencies.keywordRepository
                ),
                loadRegisteredNovelStatsUseCase: DefaultLoadRegisteredNovelStatsUseCase(
                    novelRepository: dependencies.novelRepository
                ),
                loadCollectionPreviewsUseCase: DefaultLoadCollectionPreviewsUseCase(
                    collectionRepository: dependencies.collectionRepository
                ),
                logger: dependencies.logger,
                // TODO: - 컬렉션 목록 화면으로 이동(CollectionFeature가 아직 App에 연결되지 않음, docs/TODO.md 참고)
                onCollectionTapped: {},
                onEditProfileTapped: { path.append(Destination.edit) },
                onSettingTapped: { path.append(Destination.setting) },
                onLibraryTapped: onLibraryTapped
            )
            .navigationDestination(for: Destination.self) { destination in
                // 탭 콘텐츠에서 push된 화면은 탭바를 가린다(`HomeRootView`와 동일 규칙).
                Group {
                    switch destination {
                    case .edit:
                        editProfileView
                    case .setting:
                        settingView
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
        .showWSSToast(isPresented: $showProfileSavedToast, type: .editProfile)
    }
}

// MARK: - 프로필 편집

private extension MypageRootView {
    var editProfileView: some View {
        MypageFeatureFactory.makeEditView(
            loadInitialProfileUseCase: DefaultLoadProfileDraftUseCase(profileRepository: dependencies.profileRepository),
            loadProfileCharacterUseCase: DefaultLoadProfileCharacterUseCase(
                profileRepository: dependencies.profileRepository
            ),
            validateNicknameUseCase: DefaultValidateNicknameUseCase(repository: dependencies.profileRepository),
            updateProfileUseCase: DefaultUpdateProfileUseCase(profileRepository: dependencies.profileRepository),
            // `MyPageEditView`가 저장 성공 시 스스로 `dismiss()`한다(Feature 내부, 안 건드림) —
            // 여기서 또 `path.removeLast()`를 부르면 이중 pop이 된다. 토스트만 세운다.
            onSaved: { showProfileSavedToast = true },
            logger: dependencies.logger
        )
    }
}

// MARK: - 설정

private extension MypageRootView {
    var settingView: some View {
        SettingFeatureFactory.makeView(
            loadLocalGenderAndBirthUseCase: DefaultLoadLocalGenderAndBirthUseCase(
                repository: dependencies.profileRepository
            ),
            saveAccountInfoDraftUseCase: DefaultSaveAccountInfoDraftUseCase(repository: dependencies.profileRepository),
            loadAccountInfoDraftUseCase: DefaultLoadAccountInfoDraftUseCase(repository: dependencies.profileRepository),
            loadProfileVisibilityUseCase: DefaultLoadProfileVisibilityUseCase(repository: dependencies.profileRepository),
            updateProfileVisibilityUseCase: DefaultUpdateProfileVisibilityUseCase(
                repository: dependencies.profileRepository
            ),
            loadBlockedUsersUseCase: DefaultLoadBlockedUsersUseCase(repository: dependencies.socialRepository),
            unblockUserUseCase: DefaultUnblockUserUseCase(repository: dependencies.socialRepository),
            loadPushPreferenceUseCase: DefaultLoadPushPreferenceUseCase(repository: dependencies.pushSettingRepository),
            updatePushPreferenceUseCase: DefaultUpdatePushPreferenceUseCase(
                repository: dependencies.pushSettingRepository
            ),
            loadNovelNotificationSubscriptionsUseCase: DefaultLoadNovelNotificationSubscriptionsUseCase(
                repository: dependencies.novelNotificationRepository
            ),
            deleteNovelNotificationSubscriptionsUseCase: DefaultDeleteNovelNotificationSubscriptionsUseCase(
                repository: dependencies.novelNotificationRepository
            ),
            withdrawUseCase: DefaultWithdrawUseCase(repository: dependencies.authRepository),
            logoutUseCase: DefaultLogoutUseCase(authRepository: dependencies.authRepository),
            loadRegisteredNovelStatsUseCase: DefaultLoadRegisteredNovelStatsUseCase(
                novelRepository: dependencies.novelRepository
            ),
            pushAuthorizationChecker: DefaultPushAuthorizationChecker(),
            logger: dependencies.logger,
            // 회원탈퇴/로그아웃 둘 다 세션을 끝낸다 — 다른 탭의 401 만료와 같은 경로로 온보딩까지 되돌린다.
            onWithdrawSuccess: onAuthenticationRequired,
            onLogoutSuccess: onAuthenticationRequired
        )
    }
}
