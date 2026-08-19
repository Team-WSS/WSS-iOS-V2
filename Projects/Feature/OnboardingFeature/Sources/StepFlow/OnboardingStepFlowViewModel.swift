//
//  OnboardingStepFlowViewModel.swift
//  OnboardingFeature
//
//  Created by Guryss on 8/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Observation

import ProfileDomain

/// 온보딩 나머지 3단계(닉네임→성별/출생년도→장르선택)의 **단계 전환만** 소유하는 얇은 조정용 VM —
/// 각 단계의 실제 입력 상태·검증 로직은 여전히 `NicknameViewModel`/`GenderBirthYearViewModel`/
/// `GenreSelectionViewModel`이 각자 갖는다(이 VM은 그걸 대체하지 않는다). 뒤로가기는 `NavigationStack`
/// pop이 아니라 여기서 `currentStep`만 되돌린다 — 세 단계가 이제 한 화면(`OnboardingStepFlowView`) 안의
/// 콘텐츠 전환이라 화면 자체가 사라지지 않기 때문(진행바가 같은 인스턴스로 남아있어야 부드럽게 애니메이션된다).
@MainActor
@Observable
final class OnboardingStepFlowViewModel {

    // MARK: - State

    enum Step: Int {
        case nickname = 1
        case genderBirthYear = 2
        case genreSelection = 3
    }

    struct State {
        var currentStep: Step = .nickname
        var nickname = ""
    }

    // MARK: - Action

    enum Action {
        case nicknameConfirmed(String)
        case genderBirthYearConfirmed(Gender, BirthYear)
        case goBack
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .nicknameConfirmed(let nickname):
            state.nickname = nickname
            state.currentStep = .genderBirthYear
        case .genderBirthYearConfirmed:
            state.currentStep = .genreSelection
        case .goBack:
            goBack()
        }
    }
}

// MARK: - Action Handling

private extension OnboardingStepFlowViewModel {
    /// 1단계(닉네임)엔 뒤로가기 버튼 자체가 없어(View가 숨김) 이 케이스는 실제로 호출되지 않는다 — 그래도
    /// 방어적으로 no-op 처리.
    func goBack() {
        switch state.currentStep {
        case .nickname:
            break
        case .genderBirthYear:
            state.currentStep = .nickname
        case .genreSelection:
            state.currentStep = .genderBirthYear
        }
    }
}
