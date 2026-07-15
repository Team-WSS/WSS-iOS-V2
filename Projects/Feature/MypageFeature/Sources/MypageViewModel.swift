//
//  MypageViewModel.swift
//  MypageFeature
//
//  Created by Seoyeon Choi on 7/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import ProfileDomain
import NovelDomain
import Logger

@MainActor
@Observable
final class MypageViewModel {

    // MARK: - State

    struct State {
        var profile: Profile?
        var genrePreferences: [GenrePreference] = []
        var novelPreference: NovelPreference?
        var registeredNovelStats: RegisteredNovelStats?
        var isLoading = false
        var hasLoadError = false
    }

    // MARK: - Derived

    /// 서버가 이미 뱃지 개수 내림차순으로 내려준다(클라이언트에서 재정렬하지 않음).
    /// 대표 3개/펼침 목록 분리에만 쓴다.
    var topGenrePreferences: [GenrePreference] {
        Array(state.genrePreferences.prefix(3))
    }

    var remainingGenrePreferences: [GenrePreference] {
        Array(state.genrePreferences.dropFirst(3))
    }

    var totalGenreBadgeCount: Int {
        state.genrePreferences.reduce(0) { $0 + $1.count }
    }

    var keywordPreferences: [KeywordPreference] {
        state.novelPreference?.keywords ?? []
    }

    /// 장르 취향이 비어있거나 있어도 전부 0개인 경우 → `myGenreSection`(장르 뱃지) 자체를 숨긴다.
    var hasNoGenrePreferenceData: Bool {
        state.genrePreferences.allSatisfy { $0.count == 0 }
    }

    /// 작품 취향(매력 포인트+키워드) 데이터가 아예 없거나, 장르 취향이 있어도 전부 0개면
    /// → 타이틀("주로 보는 작품은...")은 유지한 채 콘텐츠만 `preferenceNodataSection`으로 대체.
    var hasNoPreferenceData: Bool {
        let hasNoNovelPreference = (state.novelPreference?.attractivePoints.isEmpty ?? true)
            && (state.novelPreference?.keywords.isEmpty ?? true)
        return hasNoNovelPreference || hasNoGenrePreferenceData
    }

    // MARK: - Action

    enum Action {
        case load
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    // MARK: - Dependency

    private let logger: Logger?

    // ProfileDomain
    private let loadProfileUseCase: LoadProfileUseCase
    private let loadGenrePreferencesUseCase: LoadGenrePreferencesUseCase
    private let loadNovelPreferencesUseCase: LoadNovelPreferencesUseCase

    // NovelDomain
    private let loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase

    // MARK: - Init

    init(
        loadProfileUseCase: LoadProfileUseCase,
        loadGenrePreferencesUseCase: LoadGenrePreferencesUseCase,
        loadNovelPreferencesUseCase: LoadNovelPreferencesUseCase,
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        logger: Logger? = nil
    ) {
        self.loadProfileUseCase = loadProfileUseCase
        self.loadGenrePreferencesUseCase = loadGenrePreferencesUseCase
        self.loadNovelPreferencesUseCase = loadNovelPreferencesUseCase
        self.loadRegisteredNovelStatsUseCase = loadRegisteredNovelStatsUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .dismissError:
            state.hasLoadError = false
        }
    }
}

// MARK: - Action Handling

private extension MypageViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        state.isLoading = true
        loadTask = Task { await loadMypage() }
    }
}

// MARK: - UseCase Handling

private extension MypageViewModel {
    /// 프로필/장르 뱃지/작품 취향/서재 통계를 병렬로 로드한다. 프로필·장르·작품 취향은 같은 `ProfileTarget.me`
    /// 대상이고, 서재 통계는 NovelDomain의 로그인 사용자 기준 조회다. 하나가 실패해도(구조적 동시성으로
    /// 나머지 자식 태스크는 스코프 종료 시 자동 정리) 화면 전체를 에러로 취급한다.
    func loadMypage() async {
        defer { loadTask = nil }
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            async let profile = loadProfileUseCase.execute(target: .me)
            async let genrePreferences = loadGenrePreferencesUseCase.execute(.me)
            async let novelPreference = loadNovelPreferencesUseCase.execute(.me)
            async let registeredNovelStats = loadRegisteredNovelStatsUseCase.execute()

            state.profile = try await profile
            state.genrePreferences = try await genrePreferences
            state.novelPreference = try await novelPreference
            state.registeredNovelStats = try await registeredNovelStats
            hasLoaded = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension MypageViewModel {
    func presentError(_ error: Error) {
        logger?.error("Mypage 로드 실패: \(String(describing: error))")
        state.hasLoadError = true
    }
}
