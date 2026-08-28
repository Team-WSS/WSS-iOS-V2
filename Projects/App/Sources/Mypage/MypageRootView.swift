//
//  MypageRootView.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CollectionFeature
import FeedFeature
import SettingFeature
import UserPageFeature
import BaseDomain
import AuthDomain
import CollectionDomain
import FeedDomain
import NotificationDomain
import NovelDomain
import ProfileDomain
import SearchDomain
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
/// ⚠️ **`CollectionFeature`의 "작품 추가"/"서재에서 추가"는 성격이 같은 로컬 값 선택기인데도 예외 없이
/// App으로 올렸다**(#201, 사용자 명시 재확정) — 이 캐릭터 시트 예외를 새 화면에 확대 적용하는 근거로
/// 쓰지 말 것. 두 화면은 "이번엔 예외를 두지 않는다"는 별도 지시로 App 소유가 됐다.
///
/// 우측 상단 톱니바퀴 → 설정(`SettingFeatureFactory.makeView`)까지 push한다. 서재 블록 탭은 push가 아니라
/// **탭 전환**이라(`MainTabView.selectedTab`) `onLibraryTapped` 콜백으로 위로 흘려보낸다.
///
/// **컬렉션(#201)**: "컬렉션 N개" 행 탭 → 컬렉션 목록(`collectionListView`)까지 push하고, 그 안의 생성·
/// 수정·상세·"작품 추가"/"서재에서 추가"까지 전부 이 루트가 조립한다(`CollectionFeatureFactory`는
/// 화면 간 이동을 스스로 하지 않는다 — 모듈 CLAUDE.md 참고). 컬렉션 상세의 작품 탭은 다른 탭과 동일하게
/// 작품 상세(`NovelDetailAssembly`)까지 이어진다(#201 `docs/TODO.md` 9번의 후속 조치) — 그 상세가 다시
/// 여는 리뷰·피드 작성·피드 상세·유저 프로필·일반 검색까지 `LibraryRootView`와 동일한 구조로 이 루트에도
/// 옮겨왔다(마이페이지에서 진입했다고 그 하위 흐름이 달라질 이유가 없어서).
///
/// ⚠️ **`MypageFeatureFactory.makeView` 자체가 받는 `onAuthenticationRequired`는 없다** — 로드 401은
/// 여전히 조용히 빈 상태로 남는다(FeedFeature와 같은 사정, App 쪽에서 고칠 수 있는 부분이 아님). 다만
/// 여기서 push하는 **설정(`SettingFeatureFactory.makeView`)의 회원탈퇴/로그아웃 성공은 세션 자체를 끝내는
/// 이벤트**라, 다른 탭의 401 처리와 같은 경로(`onAuthenticationRequired` → 온보딩으로 라우팅)를 탄다.
struct MypageRootView: View {

    private enum Destination: Hashable {
        case edit
        // 설정(#201 — SettingFeature 내부 화면 전환도 전부 App이 조립한다. 예외는
        // `settingWithdrawFlow` 하나뿐 — "확인→사유" 2단계는 그 화면 안에서 여전히 로컬로 진행된다,
        // `SettingFeature/CLAUDE.md` 참고)
        case setting
        case settingAccountInfo
        case settingChangeGenderOrAge
        case settingBlockUserList
        case settingWithdrawFlow
        case settingProfilePublic
        case settingNotification
        case settingCompletionNotificationList
        case settingHiatusReturnNotificationList
        // 컬렉션(#201)
        case collectionList
        case createCollection
        case editCollection(CollectionID)
        case collectionDetail(CollectionID)
        /// "작품 추가"/"서재에서 추가" — 진입 시점의 선택 스냅샷을 path payload로 직접 실어 보낸다.
        /// **별도 `@State` 스크래치 변수에 먼저 써두고 그 값을 읽어 destination을 만드는 방식은
        /// 레이스가 있다**(실측, 2026-08-28) — 같은 액션 안에서 `scratchState = value; path.append(...)`
        /// 처럼 `@State` 갱신과 push를 연달아 해도, `.navigationDestination(for:)`가 새 destination
        /// view를 만드는 시점에 그 `@State` 갱신이 아직 반영되지 않은 이전 값(빈 배열)을 읽어버려
        /// "작품 추가"→"서재에서 추가"로 넘어갈 때 검색에서 고른 작품이 통째로 사라지는 버그로 실제
        /// 재현됐다. `CollectionNovel`이 Hashable(#201)이라 이제 배열째로 payload에 넣을 수 있다.
        case searchNovelForCollection([CollectionNovel])
        case myLibrarySelectForCollection([CollectionNovel])
        // 작품 상세와 그 하위 흐름(`LibraryRootView`/`HomeRootView`와 동일 구조)
        case novel(NovelID)
        case feed(FeedID)
        case createFeedFromNovel(ConnectedNovel)
        case editFeed(FeedID)
        case userPage(UserID)
        /// 타유저 프로필의 "활동기록 더보기" → 전체 피드 목록(#201, `UserPageAssembly.makeFeedListView`).
        case userFeedList(userID: UserID, nickname: String, profileImage: URL?)
        case novelReview(novelID: NovelID, title: String, status: ReadingStatus)
        case search
        case authorSearch(String)
        case detailSearch(SearchFilter)
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
    /// 성별/나이 변경 화면이 저장 성공으로 dismiss된 뒤, 돌아온 계정정보 화면에서 이 루트가 띄운다
    /// (`SettingFeature/CLAUDE.md`의 "저장됨" 토스트 이관 참고 — #201부터 그 화면 자신이 아니라 App이 띄운다).
    @State private var isChangeSavedToastPresented = false
    /// 프로필 공개 설정 화면이 저장 성공으로 dismiss된 뒤, 돌아온 설정 목록 화면에서 이 루트가 띄운다.
    @State private var isVisibilityChangedToastPresented = false
    @State private var visibilityChangedToastType: WSSToastType = .changePublic

    /// "작품 추가"/"서재에서 추가" 확정 결과를 생성/수정 컬렉션 화면에 돌려주는 1회성 nil→값 채널
    /// (`CollectionFeatureFactory.makeCreateCollectionView` 문서 참고). 생성·수정이 동시에 열릴 일이
    /// 없어 하나로 공유한다. **이건 진입(entry) 파라미터가 아니라 확정(return) 값**이라 위
    /// `Destination` 레이스 대상이 아니다 — 이미 mount된 `CreateCollectionView`가 `.onChange`로 값
    /// 변화를 관찰하는 구조라, "아직 mount 안 된 destination이 최신 `@State`를 못 읽는" 문제 자체가
    /// 성립하지 않는다.
    @State private var pendingCollectionNovelSelection: [CollectionNovel]?

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
                onCollectionTapped: { path.append(Destination.collectionList) },
                onCollectionItemTapped: { path.append(Destination.collectionDetail($0)) },
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
                    case .settingAccountInfo:
                        settingAccountInfoView
                    case .settingChangeGenderOrAge:
                        settingChangeGenderOrAgeView
                    case .settingBlockUserList:
                        settingBlockUserListView
                    case .settingWithdrawFlow:
                        settingWithdrawFlowView
                    case .settingProfilePublic:
                        settingProfilePublicView
                    case .settingNotification:
                        settingNotificationView
                    case .settingCompletionNotificationList:
                        settingCompletionNotificationListView
                    case .settingHiatusReturnNotificationList:
                        settingHiatusReturnNotificationListView
                    case .collectionList:
                        collectionListView
                    case .createCollection:
                        createCollectionView
                    case .editCollection(let id):
                        editCollectionView(id: id)
                    case .collectionDetail(let id):
                        collectionDetailView(id: id)
                    case .searchNovelForCollection(let initialSelection):
                        collectionSearchNovelView(initialSelection: initialSelection)
                    case .myLibrarySelectForCollection(let initialSelection):
                        collectionMyLibrarySelectView(initialSelection: initialSelection)
                    case .novel(let novelID):
                        novelDetailView(novelID)
                    case .feed(let feedID):
                        feedDetailView(feedID)
                    case .createFeedFromNovel(let connectedNovel):
                        createFeedView(connectedNovel: connectedNovel)
                    case .editFeed(let feedID):
                        FeedDetailAssembly.makeEditFeedView(feedID: feedID, dependencies: dependencies)
                    case .userPage(let userID):
                        UserPageAssembly.makeView(
                            userID: userID,
                            dependencies: dependencies,
                            onFeedListTapped: { userID, nickname, profileImage in
                                path.append(Destination.userFeedList(userID: userID, nickname: nickname, profileImage: profileImage))
                            }
                        )
                    case .userFeedList(let userID, let nickname, let profileImage):
                        UserPageAssembly.makeFeedListView(
                            userID: userID,
                            nickname: nickname,
                            profileImage: profileImage,
                            dependencies: dependencies
                        )
                    case .novelReview(let novelID, let title, let status):
                        NovelReviewAssembly.makeView(
                            novelID: novelID,
                            title: title,
                            status: status,
                            dependencies: dependencies,
                            onAuthenticationRequired: onAuthenticationRequired
                        )
                    case .search:
                        searchView()
                    case .authorSearch(let authorName):
                        searchView(initialQuery: authorName)
                    case .detailSearch(let filter):
                        detailSearchResultView(filter)
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
        .showWSSToast(isPresented: $showProfileSavedToast, type: .editProfile)
        .showWSSToast(isPresented: $isChangeSavedToastPresented, type: .changeInfo)
        .showWSSToast(isPresented: $isVisibilityChangedToastPresented, type: visibilityChangedToastType)
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

// MARK: - 설정 (#201 — 화면 간 이동은 전부 이 루트가 조립한다. 예외는 `settingWithdrawFlowView`
// 하나뿐, 그 안의 "확인→사유" 2단계는 여전히 `WithdrawFlowView`가 로컬로 진행한다)

private extension MypageRootView {
    var settingView: some View {
        SettingFeatureFactory.makeView(
            pushAuthorizationChecker: DefaultPushAuthorizationChecker(),
            logger: dependencies.logger,
            onAccountInfoTapped: { path.append(Destination.settingAccountInfo) },
            onProfilePublicTapped: { path.append(Destination.settingProfilePublic) },
            onNotificationSettingTapped: { path.append(Destination.settingNotification) }
        )
    }

    var settingAccountInfoView: some View {
        SettingFeatureFactory.makeAccountInfoView(
            loadAccountInfoDraftUseCase: DefaultLoadAccountInfoDraftUseCase(repository: dependencies.profileRepository),
            logoutUseCase: DefaultLogoutUseCase(authRepository: dependencies.authRepository),
            logger: dependencies.logger,
            // 로그아웃 성공 시 세션을 끝낸다 — 다른 탭의 401 만료와 같은 경로로 온보딩까지 되돌린다.
            onLogoutSuccess: onAuthenticationRequired,
            onChangeGenderOrAgeTapped: { path.append(Destination.settingChangeGenderOrAge) },
            onBlockUserListTapped: { path.append(Destination.settingBlockUserList) },
            onWithdrawTapped: { path.append(Destination.settingWithdrawFlow) }
        )
    }

    var settingChangeGenderOrAgeView: some View {
        SettingFeatureFactory.makeChangeGenderOrAgeView(
            loadLocalGenderAndBirthUseCase: DefaultLoadLocalGenderAndBirthUseCase(
                repository: dependencies.profileRepository
            ),
            saveAccountInfoDraftUseCase: DefaultSaveAccountInfoDraftUseCase(repository: dependencies.profileRepository),
            logger: dependencies.logger,
            onSaveSuccess: { isChangeSavedToastPresented = true }
        )
    }

    var settingBlockUserListView: some View {
        SettingFeatureFactory.makeBlockUserListView(
            loadBlockedUsersUseCase: DefaultLoadBlockedUsersUseCase(repository: dependencies.socialRepository),
            unblockUserUseCase: DefaultUnblockUserUseCase(repository: dependencies.socialRepository),
            logger: dependencies.logger
        )
    }

    /// "확인→사유" 2단계는 `WithdrawFlowView` 안에서 여전히 로컬로 진행된다(사용자 확정) — 이 루트는
    /// 진입점 하나만 push하면 된다.
    var settingWithdrawFlowView: some View {
        SettingFeatureFactory.makeWithdrawFlowView(
            loadRegisteredNovelStatsUseCase: DefaultLoadRegisteredNovelStatsUseCase(
                novelRepository: dependencies.novelRepository
            ),
            withdrawUseCase: DefaultWithdrawUseCase(repository: dependencies.authRepository),
            logger: dependencies.logger,
            // 탈퇴 성공 시 세션을 끝낸다 — 다른 탭의 401 만료와 같은 경로로 온보딩까지 되돌린다.
            onWithdrawSuccess: onAuthenticationRequired
        )
    }

    var settingProfilePublicView: some View {
        SettingFeatureFactory.makeProfilePublicView(
            loadProfileVisibilityUseCase: DefaultLoadProfileVisibilityUseCase(repository: dependencies.profileRepository),
            updateProfileVisibilityUseCase: DefaultUpdateProfileVisibilityUseCase(
                repository: dependencies.profileRepository
            ),
            logger: dependencies.logger,
            onSaveSuccess: { isPublic in
                visibilityChangedToastType = isPublic ? .changePublic : .changePrivate
                isVisibilityChangedToastPresented = true
            }
        )
    }

    var settingNotificationView: some View {
        SettingFeatureFactory.makeNotificationSettingView(
            loadPushPreferenceUseCase: DefaultLoadPushPreferenceUseCase(repository: dependencies.pushSettingRepository),
            updatePushPreferenceUseCase: DefaultUpdatePushPreferenceUseCase(
                repository: dependencies.pushSettingRepository
            ),
            logger: dependencies.logger,
            onCompletionListTapped: { path.append(Destination.settingCompletionNotificationList) },
            onHiatusReturnListTapped: { path.append(Destination.settingHiatusReturnNotificationList) }
        )
    }

    var settingCompletionNotificationListView: some View {
        SettingFeatureFactory.makeCompletionNotificationListView(
            loadNovelNotificationSubscriptionsUseCase: DefaultLoadNovelNotificationSubscriptionsUseCase(
                repository: dependencies.novelNotificationRepository
            ),
            deleteNovelNotificationSubscriptionsUseCase: DefaultDeleteNovelNotificationSubscriptionsUseCase(
                repository: dependencies.novelNotificationRepository
            ),
            logger: dependencies.logger,
            onBrowseNovels: { path.append(Destination.search) }
        )
    }

    var settingHiatusReturnNotificationListView: some View {
        SettingFeatureFactory.makeHiatusReturnNotificationListView(
            loadNovelNotificationSubscriptionsUseCase: DefaultLoadNovelNotificationSubscriptionsUseCase(
                repository: dependencies.novelNotificationRepository
            ),
            deleteNovelNotificationSubscriptionsUseCase: DefaultDeleteNovelNotificationSubscriptionsUseCase(
                repository: dependencies.novelNotificationRepository
            ),
            logger: dependencies.logger,
            onBrowseNovels: { path.append(Destination.search) }
        )
    }
}

// MARK: - 컬렉션 (#201)

private extension MypageRootView {
    var collectionListView: some View {
        CollectionFeatureFactory.makeCollectionListView(
            userID: UserID(currentUserID ?? 0),
            loadCollectionsUseCase: DefaultLoadCollectionsUseCase(collectionRepository: dependencies.collectionRepository),
            loadLikedCollectionsUseCase: DefaultLoadLikedCollectionsUseCase(
                collectionRepository: dependencies.collectionRepository
            ),
            logger: dependencies.logger,
            onAuthenticationRequired: onAuthenticationRequired,
            onCreateTapped: { path.append(Destination.createCollection) },
            onCollectionSelected: { path.append(Destination.collectionDetail($0)) }
        )
    }

    var createCollectionView: some View {
        CollectionFeatureFactory.makeCreateCollectionView(
            createCollectionUseCase: DefaultCreateCollectionUseCase(collectionRepository: dependencies.collectionRepository),
            logger: dependencies.logger,
            pendingNovelSelection: $pendingCollectionNovelSelection,
            onAddNovelTapped: handleCollectionAddNovelTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    func editCollectionView(id: CollectionID) -> some View {
        CollectionFeatureFactory.makeEditCollectionView(
            id: id,
            updateCollectionUseCase: DefaultUpdateCollectionUseCase(collectionRepository: dependencies.collectionRepository),
            loadCollectionDetailUseCase: DefaultLoadCollectionDetailUseCase(
                collectionRepository: dependencies.collectionRepository
            ),
            logger: dependencies.logger,
            pendingNovelSelection: $pendingCollectionNovelSelection,
            onAddNovelTapped: handleCollectionAddNovelTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    func collectionDetailView(id: CollectionID) -> some View {
        CollectionFeatureFactory.makeCollectionDetailView(
            id: id,
            loadCollectionDetailUseCase: DefaultLoadCollectionDetailUseCase(
                collectionRepository: dependencies.collectionRepository
            ),
            collectionLikeUseCase: DefaultCollectionLikeUseCase(collectionRepository: dependencies.collectionRepository),
            deleteCollectionUseCase: DefaultDeleteCollectionUseCase(collectionRepository: dependencies.collectionRepository),
            logger: dependencies.logger,
            onAuthenticationRequired: onAuthenticationRequired,
            onNovelTapped: { path.append(Destination.novel($0)) },
            onEditTapped: { path.append(Destination.editCollection(id)) }
        )
    }

    func collectionSearchNovelView(initialSelection: [CollectionNovel]) -> some View {
        CollectionFeatureFactory.makeSearchNovelView(
            initialSelection: initialSelection,
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: dependencies.searchRepository),
            logger: dependencies.logger,
            onConfirm: handleCollectionSearchNovelConfirm,
            onLibrarySelectTapped: handleCollectionLibrarySelectTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    func collectionMyLibrarySelectView(initialSelection: [CollectionNovel]) -> some View {
        CollectionFeatureFactory.makeMyLibrarySelectView(
            initialSelection: initialSelection,
            loadMyLibraryUseCase: DefaultLoadMyLibraryUseCase(
                novelRepository: dependencies.novelRepository,
                keywordRepository: dependencies.keywordRepository
            ),
            logger: dependencies.logger,
            onConfirm: handleCollectionLibrarySelectConfirm,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// "작품 추가" 타일 탭 → 검색 화면으로 push. 현재 선택을 path payload로 그대로 실어 보낸다(위
    /// `Destination.searchNovelForCollection` 문서의 레이스 회피 이유 참고).
    func handleCollectionAddNovelTapped(_ currentSelection: [CollectionNovel]) {
        path.append(Destination.searchNovelForCollection(currentSelection))
    }

    /// 검색 화면의 "완료" 확정 → 생성/수정 화면까지 1단계 pop, 결과는 `pendingCollectionNovelSelection`으로.
    func handleCollectionSearchNovelConfirm(_ novels: [CollectionNovel]) {
        pendingCollectionNovelSelection = novels
        path.removeLast(1)
    }

    /// 검색 화면의 "서재에서 추가" 탭 → 서재 선택 화면으로 push. 지금까지 고른 걸 path payload로
    /// 그대로 실어 보낸다.
    func handleCollectionLibrarySelectTapped(_ currentSelection: [CollectionNovel]) {
        path.append(Destination.myLibrarySelectForCollection(currentSelection))
    }

    /// 서재 선택 화면의 "추가" 확정 → 생성/수정 화면까지 2단계 pop(검색 화면도 함께 건너뜀 — 기획
    /// 확정 사항, `CollectionFeature/CLAUDE.md`의 "2단계 pop" 정본 참고. Feature 안에서 boolean 하나로
    /// 서브트리를 걷어내던 방식은 #201에서 App으로 옮겨오며 path를 두 단계 pop하는 방식으로 바뀌었다).
    func handleCollectionLibrarySelectConfirm(_ novels: [CollectionNovel]) {
        pendingCollectionNovelSelection = novels
        path.removeLast(2)
    }
}

// MARK: - 작품 상세 (컬렉션 상세 작품 탭 → #201 `docs/TODO.md` 9번의 후속 조치)

private extension MypageRootView {
    func novelDetailView(_ novelID: NovelID) -> some View {
        NovelDetailAssembly.makeView(
            novelID: novelID,
            dependencies: dependencies,
            onReviewTapped: { information, status in
                path.append(Destination.novelReview(novelID: information.novel.id, title: information.novel.title, status: status))
            },
            onCreateFeedTapped: { path.append(Destination.createFeedFromNovel($0)) },
            onFeedTapped: { path.append(Destination.feed($0)) },
            onUserProfileTapped: {
                // 다른 탭의 프로필 탭 이중 가드(#196)와 동일 — 내 프로필로는 절대 안 간다.
                guard $0.value != currentUserID else { return }
                path.append(Destination.userPage($0))
            },
            onNovelTapped: { path.append(Destination.novel($0)) },
            onEditFeedTapped: { path.append(Destination.editFeed($0)) },
            onAuthorTapped: { path.append(Destination.authorSearch($0)) },
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}

// MARK: - 피드 상세 (작품 상세의 피드 탭)

private extension MypageRootView {
    func feedDetailView(_ feedID: FeedID) -> some View {
        FeedDetailAssembly.makeView(
            feedID: feedID,
            dependencies: dependencies,
            onNovelTapped: { path.append(Destination.novel($0)) },
            onEditFeedTapped: { path.append(Destination.editFeed($0)) }
        )
    }
}

// MARK: - 피드 작성 (작품 상세 "나도 한마디")

private extension MypageRootView {
    /// 이 탭엔 `.createFeedFromNovel` 하나뿐이라 `connectedNovel`은 항상 값이 있다(`LibraryRootView`와 동일).
    func createFeedView(connectedNovel: ConnectedNovel) -> some View {
        FeedFeatureFactory.makeCreateFeedView(
            createFeedUseCase: DefaultCreateFeedUseCase(repository: dependencies.feedRepository),
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: dependencies.searchRepository),
            connectedNovel: connectedNovel
        )
    }
}

// MARK: - 일반 검색 (작품 상세 "작가" 탭)

private extension MypageRootView {
    /// `.authorSearch`(작가 이름 탭, 사전 검색된 결과) 전용 — 이 탭엔 `LibraryRootView`의 "웹소설 찾기"
    /// 같은 직접 진입점이 없어 `.search` 케이스는 지금 이 경로로만 도달한다.
    func searchView(initialQuery: String? = nil) -> some View {
        SearchAssembly.makeView(
            dependencies: dependencies,
            onNovelSelected: { path.append(Destination.novel($0)) },
            onDetailSearchRequested: { path.append(Destination.detailSearch($0)) },
            initialQuery: initialQuery
        )
    }

    func detailSearchResultView(_ filter: SearchFilter) -> some View {
        SearchAssembly.makeDetailSearchResultView(
            filter: filter,
            dependencies: dependencies,
            onNovelSelected: { path.append(Destination.novel($0)) }
        )
    }
}
