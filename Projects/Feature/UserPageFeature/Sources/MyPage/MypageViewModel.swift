//
//  MypageViewModel.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import ProfileDomain
import NovelDomain
import CollectionDomain
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
        var collectionPreviews: [CollectionPreview] = []
        /// 컬렉션 섹션의 "N개" — 미리보기 배열 개수(최대 3)가 아니라 전체 개수(서버 응답의
        /// `collectionsCount`, `CollectionDomain/CLAUDE.md` 참고)다.
        var collectionCount = 0
        var isLoading = false
        var hasLoadError: RepositoryError?
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호(Feature 공통 계약).
        /// 로드가 401이면 실패 뷰로 덮지 않고 이 신호로 로그인 유도한다.
        var requiresAuthentication = false
    }

    // MARK: - Derived

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

    /// 로딩 뷰로 화면을 덮어도 되는 순간 — **아직 보여줄 게 없을 때뿐**이다.
    /// 마이페이지는 탭 복귀마다 다시 로드하므로, 이미 그린 콘텐츠까지 매번 걷어내면
    /// 프로필 편집에서 저장하고 돌아올 때마다 화면이 통째로 깜빡인다.
    var isInitialLoading: Bool {
        state.isLoading && !hasLoadedContent
    }

    // MARK: - Action

    enum Action {
        case load
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var loadTask: Task<Void, Never>?

    /// 지금 화면에 그릴 콘텐츠가 서 있는지. `state`의 옵셔널 필드로 판단하지 않는다 — 갱신이 실패해도
    /// 필드엔 직전 성공 데이터가 그대로 남아 있어, 그걸로 보면 실패 뷰에서 재시도할 때 로딩 대신
    /// 옛 화면이 잠깐 되살아났다가 다시 실패 뷰로 튄다.
    @ObservationIgnored private var hasLoadedContent = false

    /// 마이페이지 섹션은 최대 3개만 보여준다(디자인) — 서재 카운트 카드처럼 상수는 화면이 쥔다.
    private static let collectionPreviewSize = 3

    // MARK: - Dependency

    private let userID: UserID
    private let logger: Logger?

    // ProfileDomain
    private let loadProfileUseCase: LoadProfileUseCase
    private let loadGenrePreferencesUseCase: LoadGenrePreferencesUseCase
    private let loadNovelPreferencesUseCase: LoadNovelPreferencesUseCase

    // NovelDomain
    private let loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase

    // CollectionDomain
    private let loadCollectionPreviewsUseCase: LoadCollectionPreviewsUseCase

    // MARK: - Init

    init(
        userID: UserID,
        loadProfileUseCase: LoadProfileUseCase,
        loadGenrePreferencesUseCase: LoadGenrePreferencesUseCase,
        loadNovelPreferencesUseCase: LoadNovelPreferencesUseCase,
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        loadCollectionPreviewsUseCase: LoadCollectionPreviewsUseCase,
        logger: Logger? = nil
    ) {
        self.userID = userID
        self.loadProfileUseCase = loadProfileUseCase
        self.loadGenrePreferencesUseCase = loadGenrePreferencesUseCase
        self.loadNovelPreferencesUseCase = loadNovelPreferencesUseCase
        self.loadRegisteredNovelStatsUseCase = loadRegisteredNovelStatsUseCase
        self.loadCollectionPreviewsUseCase = loadCollectionPreviewsUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        }
    }
}

// MARK: - Action Handling

private extension MypageViewModel {
    /// 화면이 (재)등장할 때마다 다시 불러온다 — 프로필 편집에서 저장하고 돌아왔을 때 바뀐 값을
    /// 반영하려면, 최초 1회만 로드하는 가드를 두면 안 된다(뒤로가기로 돌아와도 onAppear는 다시 불린다).
    func load() {
        guard loadTask == nil else { return }
        state.isLoading = true
        state.hasLoadError = nil
        loadTask = Task { await loadMypage() }
    }
}

// MARK: - UseCase Handling

private extension MypageViewModel {
    /// 프로필/장르 뱃지/작품 취향/서재 통계/컬렉션 미리보기를 병렬로 로드한다. 프로필·장르·작품 취향은
    /// 같은 `ProfileTarget.me` 대상이고, 서재 통계는 NovelDomain의 로그인 사용자 기준 조회, 컬렉션
    /// 미리보기는 `LoadCollectionPreviewsUseCase.execute(userID:size:3)`(마이페이지 섹션 전용 API가
    /// 없어 목록 API를 size=3으로 호출 — `CollectionDomain/CLAUDE.md` 참고). 하나가 실패해도(구조적
    /// 동시성으로 나머지 자식 태스크는 스코프 종료 시 자동 정리) 화면 전체를 에러로 취급한다.
    func loadMypage() async {
        defer { loadTask = nil }
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            async let profile = loadProfileUseCase.execute(target: .me)
            async let genrePreferences = loadGenrePreferencesUseCase.execute(.me)
            async let novelPreference = loadNovelPreferencesUseCase.execute(.me)
            async let registeredNovelStats = loadRegisteredNovelStatsUseCase.execute()
            async let collectionPreviews = loadCollectionPreviewsUseCase.execute(userID: userID, size: Self.collectionPreviewSize)

            let loadedProfile = try await profile
            let loadedGenrePreferences = try await genrePreferences
            let loadedNovelPreference = try await novelPreference
            let loadedRegisteredNovelStats = try await registeredNovelStats
            let (loadedCollectionPreviews, loadedCollectionCount) = try await collectionPreviews

            // 플래그를 state보다 먼저 올린다 — 관찰 대상이 아니라 갱신을 스스로 트리거하지 않으므로,
            // 뷰를 깨우는 state 대입 시점에 이미 최신값이어야 한다.
            hasLoadedContent = true

            state.profile = loadedProfile
            state.genrePreferences = loadedGenrePreferences
            state.novelPreference = loadedNovelPreference
            state.registeredNovelStats = loadedRegisteredNovelStats
            state.collectionPreviews = loadedCollectionPreviews
            state.collectionCount = loadedCollectionCount
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension MypageViewModel {
    func presentError(_ error: Error) {
        // 인증 만료는 실패 뷰보다 먼저 거른다 — 세션이 죽은 상태라 재시도가 같은 401로 돌아와
        // 갇히므로 로그인 유도로 일원화한다(Feature 공통 "인증 만료 처리 계약").
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("Mypage 로드 실패: \(String(describing: error))")
        // 실패 뷰가 화면을 덮으므로 "보이는 콘텐츠"는 없어진다 — 이걸 내려야 재시도 때 옛 화면이
        // 되살아나지 않고 로딩부터 다시 시작한다.
        hasLoadedContent = false
        state.hasLoadError = (error as? RepositoryError) ?? .unknown
    }

    /// 인증 만료(`authenticationRequired`)면 로그인 라우팅 신호를 세우고 true 반환.
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
