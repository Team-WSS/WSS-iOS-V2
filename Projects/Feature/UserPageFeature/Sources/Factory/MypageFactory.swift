//
//  MypageFactory.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import ProfileDomain
import NovelDomain
import Logger

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 internal로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
public enum MypageFactory {

    @MainActor
    public static func makeView(
        loadProfileUseCase: LoadProfileUseCase,
        loadGenrePreferencesUseCase: LoadGenrePreferencesUseCase,
        loadNovelPreferencesUseCase: LoadNovelPreferencesUseCase,
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        loadInitialProfileUseCase: LoadInitialProfileUseCase,
        loadProfileCharacterUseCase: LoadProfileCharacterUseCase,
        validateNicknameUseCase: ValidateNicknameUseCase,
        updateProfileUseCase: UpdateProfileUseCase,
        logger: Logger? = nil
    ) -> some View {
        let viewModel = MypageViewModel(
            loadProfileUseCase: loadProfileUseCase,
            loadGenrePreferencesUseCase: loadGenrePreferencesUseCase,
            loadNovelPreferencesUseCase: loadNovelPreferencesUseCase,
            loadRegisteredNovelStatsUseCase: loadRegisteredNovelStatsUseCase,
            logger: logger
        )
        return MypageView(
            viewModel: viewModel,
            loadInitialProfileUseCase: loadInitialProfileUseCase,
            loadProfileCharacterUseCase: loadProfileCharacterUseCase,
            validateNicknameUseCase: validateNicknameUseCase,
            updateProfileUseCase: updateProfileUseCase,
            logger: logger
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
