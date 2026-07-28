//
//  MyPageEditViewModel.swift
//  MypageFeature
//
//  Created by Seoyeon Choi on 7/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import ProfileDomain
import Logger

@MainActor
@Observable
final class MyPageEditViewModel {

    // MARK: - State

    struct State {
        var draft: ProfileDraft
        var characters: [ProfileCharacter] = []
        var isLoading = false
        var loadFailed = false
        var isCheckingNickname = false
        var isSaving = false
        var presentedError = false
        var shouldDismiss = false
    }

    // MARK: - Derived

    var selectedCharacterImage: URL? {
        state.characters.first { $0.id == state.draft.characterID }?.thumbnailImage
    }

    // MARK: - Action

    enum Action {
        case load
        case updateNickname(String)
        case checkNicknameDuplication
        case updateIntroduction(String)
        case toggleGenrePreference(NovelGenre)
        case selectCharacter(Int)
        case save
        case dismissError
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    @ObservationIgnored private var loadTask: Task<Void, Never>?

    // MARK: - Dependency

    private let logger: Logger?

    // ProfileDomain
    private let loadInitialProfileUseCase: LoadInitialProfileUseCase
    private let loadProfileCharacterUseCase: LoadProfileCharacterUseCase
    private let validateNicknameUseCase: ValidateNicknameUseCase
    private let updateProfileUseCase: UpdateProfileUseCase

    // MARK: - Init

    init(
        loadInitialProfileUseCase: LoadInitialProfileUseCase,
        loadProfileCharacterUseCase: LoadProfileCharacterUseCase,
        validateNicknameUseCase: ValidateNicknameUseCase,
        updateProfileUseCase: UpdateProfileUseCase,
        logger: Logger? = nil
    ) {
        self.loadInitialProfileUseCase = loadInitialProfileUseCase
        self.loadProfileCharacterUseCase = loadProfileCharacterUseCase
        self.validateNicknameUseCase = validateNicknameUseCase
        self.updateProfileUseCase = updateProfileUseCase
        self.logger = logger
        self.state = State(draft: ProfileDraft(characterID: 0, nickname: "", introduction: "", genrePreferences: []))
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .updateNickname(let value):
            state.draft.updateNickname(value)
        case .checkNicknameDuplication:
            checkNicknameDuplication()
        case .updateIntroduction(let value):
            state.draft.updateIntroduction(value)
        case .toggleGenrePreference(let genre):
            toggleGenrePreference(genre)
        case .selectCharacter(let characterID):
            state.draft.setCharacter(characterID)
        case .save:
            save()
        case .dismissError:
            state.presentedError = false
        }
    }
}

// MARK: - Action Handling

private extension MyPageEditViewModel {
    /// 화면에 (재)진입할 때마다 항상 서버/로컬의 확정 상태를 다시 불러온다 — 단발 로드 가드를 두면
    /// 완료를 누르지 않고 나갔다 들어왔을 때 직전 세션의 미저장 선택(캐릭터 등)이 남아있는 화면을 볼 수 있다.
    func load() {
        guard loadTask == nil else { return }
        state.isLoading = true
        state.loadFailed = false
        loadTask = Task { await loadInitial() }
    }

    /// 이미 선택된 장르면 제거, 아니면 count 0으로 새로 추가한다.
    /// `removeGenrePreference`는 완전 일치(Equatable) 비교라 genre만으로 새로 만든 값으론 지워지지 않는다 —
    /// 반드시 draft에 실제로 들어있는 인스턴스(count 포함)를 찾아 넘겨야 한다.
    func toggleGenrePreference(_ genre: NovelGenre) {
        if let existing = state.draft.genrePreferences.first(where: { $0.genre == genre }) {
            state.draft.removeGenrePreference(existing)
        } else {
            state.draft.addGenrePreference(GenrePreference(genre: genre, count: 0))
        }
    }

    /// 실제로 서버 확인이 필요한 상태(`needDuplicatedCheck`)일 때만 호출을 보낸다.
    func checkNicknameDuplication() {
        guard state.draft.nickname.validationState == .needDuplicatedCheck else { return }
        let text = state.draft.nickname.text
        Task { await validateNickname(text) }
    }

    func save() {
        guard state.draft.isSubmittable, !state.isSaving else { return }
        Task { await saveProfile() }
    }
}

// MARK: - UseCase Handling

private extension MyPageEditViewModel {
    /// 초안(닉네임·소개·장르·캐릭터ID)과 캐릭터 목록(프로필 이미지 미리보기 해석용)을 병렬로 로드한다.
    func loadInitial() async {
        defer { loadTask = nil; state.isLoading = false }
        do {
            async let draft = loadInitialProfileUseCase.execute()
            async let characters = loadProfileCharacterUseCase.execute()
            let loadedDraft = try await draft
            let loadedCharacters = try await characters

            state.draft = resolvedDraft(loadedDraft, characters: loadedCharacters)
            state.characters = loadedCharacters
        } catch {
            logger?.error("MyPageEdit 로드 실패: \(String(describing: error))")
            state.loadFailed = true
        }
    }

    /// userDefaults에 캐시된 `characterID`가 실제 보유 캐릭터 목록에 없으면(캐시 미스·최초 로그인 등)
    /// 대표(`isRepresentative`) 캐릭터로 보정한다. `setCharacter`로 기존 draft를 mutate하면
    /// `isCharacterChanged`가 true가 되어 완료 버튼이 실제로는 안 바뀐 프로필을 "변경됨"으로 오판하니,
    /// 보정된 ID를 초기값으로 삼는 새 draft를 만든다.
    func resolvedDraft(_ draft: ProfileDraft, characters: [ProfileCharacter]) -> ProfileDraft {
        guard !characters.contains(where: { $0.id == draft.characterID }) else { return draft }
        let fallbackID = characters.first(where: \.isRepresentative)?.id ?? characters.first?.id ?? draft.characterID
        return ProfileDraft(
            characterID: fallbackID,
            nickname: draft.nickname.text,
            introduction: draft.introduction,
            genrePreferences: draft.genrePreferences
        )
    }

    func validateNickname(_ text: String) async {
        state.isCheckingNickname = true
        defer { state.isCheckingNickname = false }
        do {
            let isAvailable = try await validateNicknameUseCase.execute(text)
            state.draft.applyNicknameDuplicationCheck(isAvailable ? .notDuplicated : .duplicated, checkedText: text)
        } catch {
            presentError(error)
        }
    }

    /// 저장 성공 시 곧바로 닫는다. "저장됨" 토스트는 이 화면이 아니라 복귀할 부모(마이페이지)가
    /// `onSaved` 콜백을 받아 보여준다 — 여기서 sleep으로 노출 시간을 벌면 dismiss가 부자연스럽게 지연된다.
    func saveProfile() async {
        state.isSaving = true
        defer { state.isSaving = false }
        do {
            try await updateProfileUseCase.execute(state.draft)
            state.shouldDismiss = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension MyPageEditViewModel {
    func presentError(_ error: Error) {
        logger?.error("MyPageEdit 예기치 못한 에러: \(String(describing: error))")
        state.presentedError = true
    }
}
