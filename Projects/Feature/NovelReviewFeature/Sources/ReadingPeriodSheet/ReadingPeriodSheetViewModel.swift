//
//  ReadingPeriodSheetViewModel.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import NovelReviewDomain

/// 독서 기간 시트의 입력 상태/정책을 담는 ViewModel.
/// 비동기·UseCase·외부 콜백이 없는 "순수 입력" VM — 상태와 파생값만 노출하고, 결과 전달(부모 onApply 호출)은 View가 한다.
/// 시작/종료 순서 보정은 **포커스 상태에 달린 입력 UX 정책(도메인 규칙 아님)** 이라 여기 산다.
/// raw 날짜만 다루며 `ReadingPeriod` 생성·정규화는 하지 않는다 — 그건 status를 소유한 draft(부모)가 `setPeriod`에서 담당.
@MainActor
@Observable
final class ReadingPeriodSheetViewModel {

    // MARK: - State

    enum Field: Hashable { case start, end }

    struct State {
        var field: Field = .start
        var start: Date
        var end: Date
    }

    // MARK: - Derived

    /// 상태별로 segment가 가리키는(또는 단일) 편집 대상 날짜.
    var editingDate: Date {
        switch status {
        case .watching: return state.start
        case .quit:     return state.end
        case .watched:  return state.field == .start ? state.start : state.end
        }
    }

    /// 완료 시 부모로 넘길 (start, end). status별로 의미 있는 날짜만 채운다.
    /// 도메인이 다시 normalize하므로 여기선 형태만 맞춘다(단일 상태에 양쪽을 넘기면 도메인이 오검증).
    var result: (start: Date?, end: Date?) {
        switch status {
        case .watching: return (state.start, nil)
        case .quit:     return (nil, state.end)
        case .watched:  return (state.start, state.end)
        }
    }

    // MARK: - Action

    enum Action {
        case selectField(Field)
        /// 휠이 이미 직전 유효값으로 되돌린 값을 받아 watched에서 두 날짜의 순서를 보정한다.
        case updateEditingDate(Date)
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Dependency

    let status: ReadingStatus
    /// 선택 가능한 최대 날짜(보통 오늘). 휠의 미래 클램프 기준.
    let maxDate: Date

    // MARK: - Init

    init(
        status: ReadingStatus,
        period: ReadingPeriod?,
        maxDate: Date
    ) {
        self.status = status
        self.maxDate = maxDate
        self.state = State(
            start: period?.start ?? Date(),
            end: period?.end ?? Date()
        )
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .selectField(let field):
            state.field = field
        case .updateEditingDate(let date):
            applyEditedDate(date)
        }
    }
}

// MARK: - Action Handling

private extension ReadingPeriodSheetViewModel {

    /// 편집 중인 쪽이 기준. watched에서 시작이 종료를 넘으면 종료를, 종료가 시작보다 빠르면 시작을 끌어다 맞춘다.
    /// (어느 쪽이 양보하느냐는 포커스 상태에 달린 입력 UX 정책 — 도메인 규칙 아님)
    func applyEditedDate(_ newDate: Date) {
        switch status {
        case .watching:
            state.start = newDate
        case .quit:
            state.end = newDate
        case .watched:
            if state.field == .start {
                state.start = newDate
                if state.start > state.end { state.end = state.start }
            } else {
                state.end = newDate
                if state.end < state.start { state.start = state.end }
            }
        }
    }
}
