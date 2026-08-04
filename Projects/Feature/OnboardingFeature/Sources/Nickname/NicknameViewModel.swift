//
//  NicknameViewModel.swift
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
final class NicknameViewModel {

    // MARK: - State

    struct State {
        var draft = NicknameDraft("")
        var isCheckingDuplication = false
        /// "다음으로" 탭 시점의 확정 닉네임. View는 이 값이 채워지면 다음 단계 진행 콜백을 발화한다.
        var confirmedNickname: String?
        var requiresAuthentication = false
        var presentedError: NicknameError?
    }

    enum NicknameError: Equatable {
        case unknown
    }

    // MARK: - Action

    enum Action {
        case updateText(String)
        case checkDuplication
        case proceed
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Dependency

    private let logger: Logger?

    // ProfileDomain
    private let validateNicknameUseCase: ValidateNicknameUseCase

    // MARK: - Init

    init(
        validateNicknameUseCase: ValidateNicknameUseCase,
        logger: Logger? = nil
    ) {
        self.validateNicknameUseCase = validateNicknameUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .updateText(let text):
            state.draft.setText(text)
        case .checkDuplication:
            checkDuplication()
        case .proceed:
            proceed()
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension NicknameViewModel {
    /// 형식 유효 + 아직 확인 안 한 상태(`needDuplicatedCheck`)에서만 서버 호출.
    func checkDuplication() {
        guard state.draft.validationState == .needDuplicatedCheck, !state.isCheckingDuplication else { return }
        let text = state.draft.text
        state.isCheckingDuplication = true
        Task { await performDuplicationCheck(text: text) }
    }

    /// 저장 UseCase가 없다 — 최종 등록(`RegisterProfileUseCase`)은 온보딩 마지막 단계(장르 선택)에서 한 번에 이뤄진다.
    /// 이 화면은 로컬 검증만 통과시켜 호출자에게 값을 넘긴다.
    func proceed() {
        guard state.draft.validationState == .available else { return }
        state.confirmedNickname = state.draft.text
    }
}

// MARK: - UseCase Handling

private extension NicknameViewModel {
    func performDuplicationCheck(text: String) async {
        defer { state.isCheckingDuplication = false }

        do {
            let isAvailable = try await validateNicknameUseCase.execute(text)
            state.draft.applyDuplicationCheckResult(isAvailable ? .notDuplicated : .duplicated, checkedText: text)
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension NicknameViewModel {
    func presentError(_ error: Error) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("닉네임 중복 확인 실패: \(String(describing: error))")
        state.presentedError = .unknown
    }

    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
