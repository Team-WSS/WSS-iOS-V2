//
//  GenderBirthYearViewModel.swift
//  OnboardingFeature
//
//  Created by Guryss on 8/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import ProfileDomain

/// 온보딩 2단계 — 성별/출생년도 입력. 저장 UseCase가 없는 순수 입력 VM(닉네임과 동일한 판단) —
/// 실제 서버 등록은 온보딩 마지막 단계(장르 선택)에서 `RegisterProfileUseCase`로 한 번에 이뤄진다.
@MainActor
@Observable
final class GenderBirthYearViewModel {

    // MARK: - State

    struct State {
        var gender: Gender?
        /// 성별과 마찬가지로 처음엔 미선택(사용자 결정) — 출생년도 피커 시트에서 "완료"를 눌러야 채워진다.
        /// 피커 자체의 시작 위치(2000)는 값이 없는 동안의 표시일 뿐 이 상태를 미리 채우지 않는다(View 담당).
        var birthYear: BirthYear?
        /// "다음으로" 탭 시점의 확정 값. View는 이 값이 채워지면 다음 단계 진행 콜백을 발화하고, 곧바로
        /// `.consumeConfirmation`으로 다시 `nil`로 되돌린다 — `NicknameViewModel.confirmedNickname`과
        /// 같은 이유(뒤로 갔다 **같은 선택으로** 재확정하면 값이 안 바뀌어 `onChange`가 발동하지 않는
        /// 문제, 실측)로 소비 즉시 리셋하는 소진 패턴을 쓴다.
        var confirmedSelection: Selection?
    }

    struct Selection: Equatable {
        let gender: Gender
        let birthYear: BirthYear
    }

    // MARK: - Action

    enum Action {
        case selectGender(Gender)
        case selectBirthYear(Int)
        case proceed
        case consumeConfirmation
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .selectGender(let gender):
            state.gender = gender
        case .selectBirthYear(let year):
            guard let birthYear = try? BirthYear(year) else { return }
            state.birthYear = birthYear
        case .proceed:
            proceed()
        case .consumeConfirmation:
            state.confirmedSelection = nil
        }
    }
}

// MARK: - Action Handling

private extension GenderBirthYearViewModel {
    /// 성별·출생년도 둘 다 아직 안 골랐으면 진행하지 않는다("다음으로" 버튼도 같은 조건으로 비활성화 —
    /// View는 얇게 그대로 반영).
    func proceed() {
        guard let gender = state.gender, let birthYear = state.birthYear else { return }
        state.confirmedSelection = Selection(gender: gender, birthYear: birthYear)
    }
}
