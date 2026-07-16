//
//  SettingProfilePublicViewModel.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import ProfileDomain
import Logger

@MainActor
@Observable
final class SettingProfilePublicViewModel {

    // MARK: - State

    struct State {
        var isPublic = false
        var isLoading = false
        var isSaving = false
        var shouldDismiss = false
        /// 표시할 에러(의미값). 토스트 문구·아이콘 매핑은 View가 한다(얇은 ViewModel).
        var presentedError: SettingError?
    }

    /// 사용자에게 표시할 에러의 **의미값**. 카피·표현(토스트 타입)은 View가 결정한다.
    enum SettingError: Equatable {
        case unknown
    }

    // MARK: - Derived

    /// 로드 기준선(`baselineIsPublic`) 대비 바뀌었는지. 완료 버튼 활성화 여부에 쓰인다.
    var hasChanges: Bool { state.isPublic != baselineIsPublic }

    // MARK: - Action

    enum Action {
        case load
        case togglePublic(Bool)
        case save
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var baselineIsPublic = false

    // MARK: - Dependency

    private let logger: Logger?

    // ProfileDomain
    private let loadProfileVisibilityUseCase: LoadProfileVisibilityUseCase
    private let updateProfileVisibilityUseCase: UpdateProfileVisibilityUseCase

    // MARK: - Init

    init(
        loadProfileVisibilityUseCase: LoadProfileVisibilityUseCase,
        updateProfileVisibilityUseCase: UpdateProfileVisibilityUseCase,
        logger: Logger? = nil
    ) {
        self.loadProfileVisibilityUseCase = loadProfileVisibilityUseCase
        self.updateProfileVisibilityUseCase = updateProfileVisibilityUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .togglePublic(let isPublic):
            state.isPublic = isPublic
        case .save:
            save()
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension SettingProfilePublicViewModel {
    func load() {
        guard !hasLoaded else { return }
        state.isLoading = true
        Task { await loadVisibility() }
    }

    /// 완료 버튼. 현재 draft(`state.isPublic`)를 저장하고, 성공하면 화면을 닫도록 신호한다.
    func save() {
        guard !state.isSaving else { return }
        Task { await saveVisibility() }
    }
}

// MARK: - UseCase Handling

private extension SettingProfilePublicViewModel {
    func loadVisibility() async {
        defer { state.isLoading = false }

        do {
            let visibility = try await loadProfileVisibilityUseCase.execute()
            state.isPublic = visibility.isPublic
            baselineIsPublic = visibility.isPublic
            hasLoaded = true
        } catch {
            presentError(error)
        }
    }

    func saveVisibility() async {
        state.isSaving = true
        defer { state.isSaving = false }

        do {
            try await updateProfileVisibilityUseCase.execute(ProfileVisibility(isPublic: state.isPublic))
            state.shouldDismiss = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension SettingProfilePublicViewModel {
    func presentError(_ error: Error) {
        logger?.error("SettingProfilePublic 예기치 못한 에러: \(String(describing: error))")
        state.presentedError = .unknown
    }
}
