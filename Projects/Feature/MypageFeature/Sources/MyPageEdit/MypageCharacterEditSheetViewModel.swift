//
//  MypageCharacterEditSheetViewModel.swift
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
final class MypageCharacterEditSheetViewModel {

    // MARK: - State

    struct State {
        var characters: [ProfileCharacter] = []
        var selectedCharacterID: Int?
        var isLoading = false
        var hasLoadError = false
    }

    // MARK: - Action

    enum Action {
        case load
        case select(Int)
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    // MARK: - Dependency

    private let logger: Logger?

    // ProfileDomain
    private let loadProfileCharacterUseCase: LoadProfileCharacterUseCase

    // MARK: - Init

    init(
        selectedCharacterID: Int?,
        loadProfileCharacterUseCase: LoadProfileCharacterUseCase,
        logger: Logger? = nil
    ) {
        self.loadProfileCharacterUseCase = loadProfileCharacterUseCase
        self.logger = logger
        self.state = State(selectedCharacterID: selectedCharacterID)
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .select(let characterID):
            state.selectedCharacterID = characterID
        }
    }
}

// MARK: - Action Handling

private extension MypageCharacterEditSheetViewModel {
    /// 실패 후 재시도도 이 경로를 그대로 탄다 — 실패 시 `hasLoaded`가 세팅되지 않아 가드를 다시 통과한다.
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        state.isLoading = true
        state.hasLoadError = false
        loadTask = Task { await loadCharacters() }
    }
}

// MARK: - UseCase Handling

private extension MypageCharacterEditSheetViewModel {
    func loadCharacters() async {
        defer { loadTask = nil }
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let characters = try await loadProfileCharacterUseCase.execute()
            state.characters = characters
            let hasValidSelection = characters.contains { $0.id == state.selectedCharacterID }
            if !hasValidSelection {
                state.selectedCharacterID = characters.first(where: \.isRepresentative)?.id ?? characters.first?.id
            }
            hasLoaded = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension MypageCharacterEditSheetViewModel {
    func presentError(_ error: Error) {
        logger?.error("프로필 캐릭터 목록 로드 실패: \(String(describing: error))")
        state.hasLoadError = true
    }
}
