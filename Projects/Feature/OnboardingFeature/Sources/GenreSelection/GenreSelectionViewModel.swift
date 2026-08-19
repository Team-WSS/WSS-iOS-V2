//
//  GenreSelectionViewModel.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import ProfileDomain
import Logger

@MainActor
@Observable
final class GenreSelectionViewModel {

    // MARK: - State

    struct State {
        var selectedGenres: Set<NovelGenre> = []
        var isSubmitting = false
        var isCompleted = false
        var requiresAuthentication = false
        var presentedError: GenreSelectionError?
    }

    enum GenreSelectionError: Equatable {
        case unknown
    }

    // MARK: - Action

    enum Action {
        case toggleGenre(NovelGenre)
        case complete
        case skip
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Dependency

    /// 이전 단계(닉네임·성별/출생년도)에서 이미 확정된 값 — 이 화면이 온보딩의 마지막 단계라 여기서
    /// `ProfileRegistration`을 완성해 한 번에 등록한다.
    private let nickname: String
    private let gender: Gender
    private let birthYear: BirthYear
    private let logger: Logger?

    // ProfileDomain
    private let registerProfileUseCase: RegisterProfileUseCase

    // MARK: - Init

    init(
        nickname: String,
        gender: Gender,
        birthYear: BirthYear,
        registerProfileUseCase: RegisterProfileUseCase,
        logger: Logger? = nil
    ) {
        self.nickname = nickname
        self.gender = gender
        self.birthYear = birthYear
        self.registerProfileUseCase = registerProfileUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .toggleGenre(let genre):
            toggleGenre(genre)
        case .complete:
            complete()
        case .skip:
            skip()
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension GenreSelectionViewModel {
    func toggleGenre(_ genre: NovelGenre) {
        if state.selectedGenres.contains(genre) {
            state.selectedGenres.remove(genre)
        } else {
            state.selectedGenres.insert(genre)
        }
    }

    /// 하나 이상 선택했을 때만 그 선택 그대로 등록한다("완료" CTA는 그 조건에서만 활성화).
    func complete() {
        guard !state.selectedGenres.isEmpty, !state.isSubmitting else { return }
        register(genres: Array(state.selectedGenres))
    }

    /// "건너뛰기" — 현재 선택과 무관하게 장르 없이 등록한다(선호 장르 없이 시작).
    func skip() {
        guard !state.isSubmitting else { return }
        register(genres: [])
    }
}

// MARK: - UseCase Handling

private extension GenreSelectionViewModel {
    func register(genres: [NovelGenre]) {
        state.isSubmitting = true
        Task { await registerProfile(genres: genres) }
    }

    func registerProfile(genres: [NovelGenre]) async {
        defer { state.isSubmitting = false }

        let registration = ProfileRegistration(
            nickname: nickname,
            gender: gender,
            birthYear: birthYear,
            genrePreferences: genres
        )

        do {
            try await registerProfileUseCase.execute(registration)
            state.isCompleted = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension GenreSelectionViewModel {
    func presentError(_ error: Error) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("프로필 등록 실패: \(String(describing: error))")
        state.presentedError = .unknown
    }

    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
