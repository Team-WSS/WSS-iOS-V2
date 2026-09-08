//
//  MypageFeatureFactory.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import ProfileDomain
import NovelDomain
import CollectionDomain
import Logger

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 internal로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
public enum MypageFeatureFactory {

    /// - Parameters:
    ///   - userID: 컬렉션 미리보기(`fetchCollections`)가 명시적으로 요구한다 — `ProfileDomain`의
    ///     `.me`/`LoadRegisteredNovelStatsUseCase.execute()`처럼 로그인 사용자를 알아서 가리키는
    ///     계약이 아니다(`CollectionDomain/CLAUDE.md` 참고).
    ///   - onRoute: 화면 전환 의도 콜백 — 목적지·payload는 `MypageRoute`(Navigation/) 참고(#253).
    ///     `.libraryTab`은 push가 아니라 **탭 전환**이라 App이 `MainTabView.selectedTab` 변경으로 매핑한다.
    ///   - onAuthenticationRequired: 마이페이지 로드가 401로 막히면 발화 — 세션 종료라 로그인/온보딩으로
    ///     되돌리는 배선(App)에 연결한다(Feature 공통 "인증 만료 처리 계약"). idempotent해야 한다.
    @MainActor
    public static func makeView(
        userID: UserID,
        loadProfileUseCase: LoadProfileUseCase,
        loadGenrePreferencesUseCase: LoadGenrePreferencesUseCase,
        loadNovelPreferencesUseCase: LoadNovelPreferencesUseCase,
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        loadCollectionPreviewsUseCase: LoadCollectionPreviewsUseCase,
        logger: Logger? = nil,
        onRoute: @escaping (MypageRoute) -> Void,
        onAuthenticationRequired: @escaping () -> Void = {}
    ) -> some View {
        let viewModel = MypageViewModel(
            userID: userID,
            loadProfileUseCase: loadProfileUseCase,
            loadGenrePreferencesUseCase: loadGenrePreferencesUseCase,
            loadNovelPreferencesUseCase: loadNovelPreferencesUseCase,
            loadRegisteredNovelStatsUseCase: loadRegisteredNovelStatsUseCase,
            loadCollectionPreviewsUseCase: loadCollectionPreviewsUseCase,
            logger: logger
        )
        return MypageView(
            viewModel: viewModel,
            onRoute: onRoute,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    @MainActor
    public static func makeCharacterEditSheet(
        selectedCharacterID: Int?,
        nickname: String,
        loadProfileCharacterUseCase: LoadProfileCharacterUseCase,
        onApply: @escaping (Int) -> Void,
        logger: Logger? = nil
    ) -> some View {
        let viewModel = MypageCharacterEditSheetViewModel(
            selectedCharacterID: selectedCharacterID,
            loadProfileCharacterUseCase: loadProfileCharacterUseCase,
            logger: logger
        )
        return MypageCharacterEditSheet(viewModel: viewModel, nickname: nickname, onApply: onApply)
    }

    @MainActor
    public static func makeEditView(
        loadInitialProfileUseCase: LoadInitialProfileUseCase,
        loadProfileCharacterUseCase: LoadProfileCharacterUseCase,
        validateNicknameUseCase: ValidateNicknameUseCase,
        updateProfileUseCase: UpdateProfileUseCase,
        onSaved: @escaping () -> Void,
        logger: Logger? = nil
    ) -> some View {
        let viewModel = MyPageEditViewModel(
            loadInitialProfileUseCase: loadInitialProfileUseCase,
            loadProfileCharacterUseCase: loadProfileCharacterUseCase,
            validateNicknameUseCase: validateNicknameUseCase,
            updateProfileUseCase: updateProfileUseCase,
            logger: logger
        )
        return MyPageEditView(
            viewModel: viewModel,
            loadProfileCharacterUseCase: loadProfileCharacterUseCase,
            logger: logger,
            onSaved: onSaved
        )
    }
}
