//
//  SettingProfilePublicViewModel.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
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
        /// 최초 로드 실패(에러 종류). 전체화면 `NetworkErrorView`에 넘겨 3분류 문구를 분기한다 — 저장 실패와 분리한다.
        /// 하나로 합치면 저장 실패 시에도 화면 전체가 에러로 뒤덮여, 방금 토글하던 화면으로 되돌아올 방법이 없어진다.
        var loadError: RepositoryError?
        /// 저장 실패(의미값). 토스트 표시용 — 화면은 그대로 두고 토글 값도 유지한다.
        var toastError: SettingError?
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
            state.toastError = nil
        }
    }
}

// MARK: - Action Handling

private extension SettingProfilePublicViewModel {
    func load() {
        guard !hasLoaded else { return }
        state.isLoading = true
        state.loadError = nil
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
            presentLoadError(error)
        }
    }

    func saveVisibility() async {
        state.isSaving = true
        defer { state.isSaving = false }

        do {
            try await updateProfileVisibilityUseCase.execute(ProfileVisibility(isPublic: state.isPublic))
            state.shouldDismiss = true
        } catch {
            presentToastError(error)
        }
    }
}

// MARK: - Error Mapping

private extension SettingProfilePublicViewModel {
    func presentLoadError(_ error: Error) {
        logger?.error("SettingProfilePublic 로드 실패: \(String(describing: error))")
        state.loadError = (error as? RepositoryError) ?? .unknown
    }

    func presentToastError(_ error: Error) {
        logger?.error("SettingProfilePublic 예기치 못한 에러: \(String(describing: error))")
        state.toastError = .unknown
    }
}
