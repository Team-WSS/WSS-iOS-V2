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
    ///   - onCollectionTapped: 컬렉션 섹션 헤더 행 탭 콜백. 실제 화면 전환(`CollectionFeature`의
    ///     목록 화면으로 이동)은 호출자(App 조정 계층)가 수행한다 — 두 Feature는 서로 import 못 한다.
    ///   - onEditProfileTapped: 프로필 편집 진입 콜백. 실제 화면 전환(`makeEditView` 조립)은
    ///     호출자(App 조정 계층)가 수행한다 — 캐릭터 선택 시트(`makeCharacterEditSheet`)와 달리 프로필
    ///     편집은 별개 화면으로의 진짜 이동이라 이 모듈 안에서 직접 열지 않는다.
    ///   - onSettingTapped: 우측 상단 톱니바퀴 → 설정 진입 콜백. 실제 화면 전환(`SettingFactory.makeView`
    ///     조립)은 호출자가 수행한다.
    ///   - onLibraryTapped: 서재 블록 탭 → "서재" 탭으로 전환 콜백. 화면 push가 아니라 탭 전환이라
    ///     호출자(App)가 자기 `TabView` selection을 바꾸는 방식으로 처리한다.
    @MainActor
    public static func makeView(
        userID: UserID,
        loadProfileUseCase: LoadProfileUseCase,
        loadGenrePreferencesUseCase: LoadGenrePreferencesUseCase,
        loadNovelPreferencesUseCase: LoadNovelPreferencesUseCase,
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        loadCollectionPreviewsUseCase: LoadCollectionPreviewsUseCase,
        logger: Logger? = nil,
        onCollectionTapped: @escaping () -> Void,
        onEditProfileTapped: @escaping () -> Void,
        onSettingTapped: @escaping () -> Void,
        onLibraryTapped: @escaping () -> Void
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
            onCollectionTapped: onCollectionTapped,
            onEditProfileTapped: onEditProfileTapped,
            onSettingTapped: onSettingTapped,
            onLibraryTapped: onLibraryTapped
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
