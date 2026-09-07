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
import Analytics

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
        /// 앞 단계(닉네임·성별/출생연도)에서 확정된 값을 주입한다 — 이 VM은 컨테이너가 미리 만들어 **항상
        /// mount**하므로(다른 단계 VM과 동일) 값은 생성이 아니라 성별/출생연도 확정 시점에 이 액션으로 받는다.
        case setProfileContext(nickname: String, gender: Gender, birthYear: BirthYear)
        case complete
        case skip
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    /// 이전 단계에서 확정돼 등록 시 `ProfileRegistration`을 완성하는 데 쓰는 값. **생성 시엔 없고**
    /// (컨테이너가 이 VM을 처음부터 만들어 항상 mount하므로), 성별/출생연도 확정 시 `setProfileContext`로
    /// 채워진다. 장르 단계는 그 확정 뒤에만 도달하므로 등록 시점엔 항상 채워져 있다(guard로 방어).
    @ObservationIgnored private var nickname: String?
    @ObservationIgnored private var gender: Gender?
    @ObservationIgnored private var birthYear: BirthYear?

    // MARK: - Dependency

    private let logger: Logger?
    private let analyticsTracker: AnalyticsTracker?

    // ProfileDomain
    private let registerProfileUseCase: RegisterProfileUseCase

    // MARK: - Init

    init(
        registerProfileUseCase: RegisterProfileUseCase,
        logger: Logger? = nil,
        analyticsTracker: AnalyticsTracker? = nil
    ) {
        self.registerProfileUseCase = registerProfileUseCase
        self.logger = logger
        self.analyticsTracker = analyticsTracker
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .toggleGenre(let genre):
            toggleGenre(genre)
        case .setProfileContext(let nickname, let gender, let birthYear):
            self.nickname = nickname
            self.gender = gender
            self.birthYear = birthYear
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
        analyticsTracker?.track(GenreSelectionAnalyticsEvent(genre: genre))
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

        // 앞 단계 값이 아직 안 들어왔으면(정상 흐름에선 성별/출생연도 확정 때 setProfileContext로 채워진다)
        // 등록을 진행하지 않는다 — 컨테이너가 항상 mount하되 값 주입은 확정 시점이라 방어한다.
        guard let nickname, let gender, let birthYear else {
            logger?.error("프로필 등록 시도했으나 앞 단계 값(닉네임·성별·출생연도)이 아직 주입되지 않았다")
            return
        }

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
