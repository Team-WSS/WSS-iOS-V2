//
//  SettingChangeGenderOrAgeViewModel.swift
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
final class SettingChangeGenderOrAgeViewModel {

    // MARK: - State

    struct State {
        var draft: AccountInfoDraft
        var isLoading = false
        var isSaving = false
        var shouldDismiss = false
        /// 표시할 에러(의미값). 토스트 문구·아이콘 매핑은 View가 한다(얇은 ViewModel).
        var presentedError: SettingError?
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호(Feature 공통 계약).
        /// 저장(서버 PUT) 401에만 걸린다 — 로드(`loadDraft`)는 로컬 userDefaults라 401이 없다.
        var requiresAuthentication = false
    }

    /// 사용자에게 표시할 에러의 **의미값**. 성별/출생연도는 입력단(칩·연도 휠)이 이미 유효값만 만들어
    /// 도달 가능한 경로가 네트워크/로컬 조회 실패뿐이라 케이스를 나누지 않는다.
    enum SettingError: Equatable {
        case unknown
    }

    // MARK: - Derived

    /// 로드 기준선(`baselineDraft`) 대비 draft가 바뀌었는지. 완료 버튼 활성화 여부에 쓰인다.
    var hasChanges: Bool { state.draft != baselineDraft }

    // MARK: - Action

    enum Action {
        case load
        case selectGender(Gender)
        case selectBirthYear(Int)
        case save
        case dismissError
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var baselineDraft: AccountInfoDraft

    // MARK: - Dependency

    private let logger: Logger?

    // ProfileDomain
    private let loadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase
    private let saveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase

    // MARK: - Init

    init(
        loadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase,
        saveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase,
        logger: Logger? = nil
    ) {
        self.loadLocalGenderAndBirthUseCase = loadLocalGenderAndBirthUseCase
        self.saveAccountInfoDraftUseCase = saveAccountInfoDraftUseCase
        self.logger = logger
        let initial = AccountInfoDraft(email: nil, gender: .female, birth: try! BirthYear(2000))
        self.state = State(draft: initial)
        self.baselineDraft = initial
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .selectGender(let gender):
            state.draft.setGender(gender)
        case .selectBirthYear(let year):
            setBirthYear(year)
        case .save:
            save()
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension SettingChangeGenderOrAgeViewModel {
    func load() {
        guard !hasLoaded else { return }
        state.isLoading = true
        Task { await loadDraft() }
    }

    /// 연도 휠은 이미 `BirthYear.minYear...maxYear` 범위 안에서만 값을 내놓으므로 실패하지 않는다.
    func setBirthYear(_ year: Int) {
        guard let birth = try? BirthYear(year) else { return }
        state.draft.setBirth(birth)
    }

    /// 완료 버튼. 현재 draft를 저장하고, 성공하면 화면을 닫도록 신호한다.
    func save() {
        guard !state.isSaving else { return }
        Task { await saveDraft() }
    }
}

// MARK: - UseCase Handling

private extension SettingChangeGenderOrAgeViewModel {
    func loadDraft() async {
        defer { state.isLoading = false }

        do {
            let draft = try await loadLocalGenderAndBirthUseCase.execute()
            state.draft = draft
            baselineDraft = draft
            hasLoaded = true
        } catch {
            presentError(error)
        }
    }

    func saveDraft() async {
        state.isSaving = true
        defer { state.isSaving = false }

        do {
            try await saveAccountInfoDraftUseCase.execute(state.draft)
            state.shouldDismiss = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension SettingChangeGenderOrAgeViewModel {
    func presentError(_ error: Error) {
        // 저장(서버 PUT) 401이면 로그인 유도로 일원화(Feature 공통 계약). 로컬 로드 실패는 여기서 걸리지 않는다.
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("SettingChangeGenderOrAge 예기치 못한 에러: \(String(describing: error))")
        state.presentedError = .unknown
    }

    /// 인증 만료(`authenticationRequired`)면 로그인 라우팅 신호를 세우고 true 반환(Feature 공통 계약).
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
