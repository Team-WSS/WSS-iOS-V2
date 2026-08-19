//
//  TermsAgreementViewModel.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/3/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import SettingDomain
import Logger

@MainActor
@Observable
final class TermsAgreementViewModel {

    // MARK: - State

    struct State {
        var draft = TermsAgreementDraft()
        var isLoading = false
        /// 초안 로드 실패 → 전면 실패 뷰(재시도). 저장 실패와 분리(NovelReview와 동일 관례).
        var loadFailed = false
        var isSaving = false
        /// 저장 성공 시점에 채워진다 — View는 이 값이 true가 되면 다음 온보딩 단계 진행 콜백을 발화한다.
        var shouldProceed = false
        var requiresAuthentication = false
        var presentedError: AgreementError?
    }

    enum AgreementError: Equatable {
        case unknown
    }

    // MARK: - Derived

    /// "전체 동의" 행의 체크 아이콘 상태 판단에 View가 쓴다.
    var isAllAgreed: Bool {
        TermsType.allCases.allSatisfy { state.draft.isAgreed($0) }
    }

    // MARK: - Action

    enum Action {
        case load
        case toggleAgreement(TermsType)
        case toggleAgreeAll
        case proceed
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false

    // MARK: - Dependency

    private let logger: Logger?

    // SettingDomain
    private let loadUseCase: LoadTermsAgreementDraftUseCase
    private let saveUseCase: SaveTermsAgreementDraftUseCase

    // MARK: - Init

    init(
        loadUseCase: LoadTermsAgreementDraftUseCase,
        saveUseCase: SaveTermsAgreementDraftUseCase,
        logger: Logger? = nil
    ) {
        self.loadUseCase = loadUseCase
        self.saveUseCase = saveUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .toggleAgreement(let type):
            state.draft.setAgreed(!state.draft.isAgreed(type), for: type)
        case .toggleAgreeAll:
            toggleAgreeAll()
        case .proceed:
            proceed()
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension TermsAgreementViewModel {
    func load() {
        guard !hasLoaded else { return }
        state.isLoading = true
        Task { await loadDraft() }
    }

    /// "전체 동의" — 필수+선택 전부 이미 동의 상태면 전부 해제, 아니면 전부 동의로 설정.
    func toggleAgreeAll() {
        let isAllAgreed = TermsType.allCases.allSatisfy { state.draft.isAgreed($0) }
        if isAllAgreed {
            for type in TermsType.allCases { state.draft.setAgreed(false, for: type) }
        } else {
            state.draft.agreeToAll()
        }
    }

    /// "다음으로" 탭 — 현재 draft를 저장하고, 성공 시 다음 단계 진행을 신호한다.
    func proceed() {
        guard !state.isSaving else { return }
        Task { await saveDraft() }
    }
}

// MARK: - UseCase Handling

private extension TermsAgreementViewModel {
    func loadDraft() async {
        defer { state.isLoading = false }

        do {
            state.draft = try await loadUseCase.execute()
            state.loadFailed = false
            hasLoaded = true
        } catch {
            if routeToLoginIfAuthenticationRequired(error) { return }
            logger?.error("TermsAgreement 로드 실패: \(String(describing: error))")
            state.loadFailed = true
        }
    }

    func saveDraft() async {
        state.isSaving = true
        defer { state.isSaving = false }

        do {
            try await saveUseCase.execute(draft: state.draft)
            state.shouldProceed = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension TermsAgreementViewModel {
    func presentError(_ error: Error) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("TermsAgreement 저장 실패: \(String(describing: error))")
        state.presentedError = .unknown
    }

    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
