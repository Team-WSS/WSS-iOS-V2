//
//  NovelReviewViewModel.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import Logger
import NovelReviewDomain

@MainActor
@Observable
final class NovelReviewViewModel {

    // MARK: - State

    struct State {
        var draft: NovelReviewDraft
        var isLoading = false
        var isSaving = false
        var shouldDismiss = false
        var isStopAlertPresented = false
        /// 표시할 에러(의미값). 토스트 문구·아이콘 매핑은 View가 한다(얇은 ViewModel).
        var presentedError: ReviewError?
    }

    /// 사용자에게 표시할 에러의 **의미값**. 카피·표현(토스트 타입)은 View가 결정한다.
    enum ReviewError: Equatable {
        /// 매력 포인트 최대 개수 초과(사용자가 정상적으로 마주칠 수 있는 검증 에러).
        case attractivePointLimit(max: Int)
        /// 그 외 — 원래 도달하면 안 되는 경로. 원인은 로그로 남긴다.
        case unknown
    }

    // MARK: - Action

    enum Action {
        case load
        case selectStatus(ReadingStatus)
        case updatePeriod(start: Date?, end: Date?)
        case updateRating(Double)
        case toggleAttractivePoint(AttractivePoint)
        case save
        case requestClose
        case confirmStop
        case keepWriting
        case dismissError
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var baselineDraft: NovelReviewDraft
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var isClosing = false

    /// 로드 기준선 대비 draft가 바뀌었는지. 뒤로가기 시 "그만 작성" 확인 알럿 노출 여부 판단에 쓴다.
    /// View가 직접 읽지 않는 내부 판단값이라 Derived가 아니라 Property에 둔다.
    private var hasUnsavedChanges: Bool { state.draft != baselineDraft }

    // MARK: - Dependency

    private let novelID: NovelID
    private let initialStatus: ReadingStatus
    private let logger: Logger?

    // NovelReviewDomain
    private let loadUseCase: LoadNovelReviewDraftUseCase
    private let saveUseCase: SaveNovelReviewUseCase

    // MARK: - Init

    init(
        novelID: NovelID,
        status: ReadingStatus,
        loadUseCase: LoadNovelReviewDraftUseCase,
        saveUseCase: SaveNovelReviewUseCase,
        logger: Logger? = nil
    ) {
        let initialDraft = NovelReviewDraft(novelID: novelID, status: status)
        self.novelID = novelID
        self.initialStatus = status
        self.state = State(draft: initialDraft)
        self.baselineDraft = initialDraft
        self.loadUseCase = loadUseCase
        self.saveUseCase = saveUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .selectStatus(let status):
            state.draft.changeStatus(status)
        case .updatePeriod(let start, let end):
            updatePeriod(start: start, end: end)
        case .updateRating(let value):
            updateRating(value)
        case .toggleAttractivePoint(let point):
            toggleAttractivePoint(point)
        case .save:
            save()
        case .requestClose:
            requestClose()
        case .confirmStop:
            confirmStop()
        case .keepWriting:
            state.isStopAlertPresented = false
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension NovelReviewViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil, !isClosing else { return }
        state.isLoading = true
        loadTask = Task { await loadDraft() }
    }

    /// 독서 기간 설정. 상태별 유효 날짜(watching=시작, watched=시작+종료, quit=종료)는
    /// 도메인 `ReadingPeriod.normalized(for:)`가 강제한다. ViewModel은 입력 날짜로 `ReadingPeriod`를 만들어 위임만 한다.
    /// 둘 다 nil이거나 시작>종료면 도메인이 throw → 사용자 메시지로 변환.
    func updatePeriod(start: Date?, end: Date?) {
        guard start != nil || end != nil else {
            state.draft.setPeriod(nil)
            return
        }
        do {
            let period = try ReadingPeriod(start: start, end: end)
            state.draft.setPeriod(period)
        } catch {
            presentError(error)
        }
    }

    /// 평점 설정. 도메인 `Rating`은 0.5~5.0(0.5 단위)만 유효하고 0.0은 표현 불가 →
    /// 슬라이더의 0.0(= 평점 없음)은 `nil`로 매핑한다.
    func updateRating(_ value: Double) {
        guard value >= 0.5 else {
            state.draft.setRating(nil)
            return
        }
        do {
            state.draft.setRating(try Rating(value))
        } catch {
            presentError(error)
        }
    }

    /// 매력 포인트 토글. 이미 선택돼 있으면 해제, 아니면 추가한다.
    /// 추가 시 최대 개수(3) 정책은 도메인(`NovelReviewDraft`)이 검증하며, 초과 시 throw → 사용자 메시지로 변환.
    func toggleAttractivePoint(_ point: AttractivePoint) {
        do {
            if state.draft.attractivePoints.contains(point) {
                state.draft.removeAttractivePoint(point)
            } else {
                try state.draft.addAttractivePoint(point)
            }
        } catch {
            presentError(error)
        }
    }

    /// 완료 버튼. 현재 draft를 저장하고, 성공하면 화면을 닫도록 신호한다.
    func save() {
        guard !state.isSaving else { return }
        Task { await saveDraft() }
    }

    /// 뒤로가기 요청. 로드 중이면 로드 완료를 기다리지 않고 닫기 흐름을 시작한다.
    func requestClose() {
        guard !isClosing else { return }

        if state.isLoading || loadTask != nil {
            close()
            return
        }

        if hasUnsavedChanges {
            state.isStopAlertPresented = true
        } else {
            close()
        }
    }

    /// "그만하기" 확인. 알럿을 내리고 닫기 신호만 View로 발화한다.
    func confirmStop() {
        state.isStopAlertPresented = false
        close()
    }

    func close() {
        isClosing = true
        state.isStopAlertPresented = false
        loadTask?.cancel()
        state.shouldDismiss = true
    }
}

// MARK: - UseCase Handling

private extension NovelReviewViewModel {

    func loadDraft() async {
        defer {
            loadTask = nil
            if !isClosing {
                state.isLoading = false
            }
        }

        do {
            if var loaded = try await loadUseCase.execute(novelID: novelID) {
                guard !isClosing, !Task.isCancelled else { return }
                baselineDraft = loaded               // 기준선은 서버에서 로드한 원본
                loaded.changeStatus(initialStatus)   // 주입된 읽기 상태를 우선 적용(원본과 다르면 '변경됨'으로 잡힘)
                state.draft = loaded
            } else {
                guard !isClosing, !Task.isCancelled else { return }
                baselineDraft = state.draft          // 초안 없음 → 초기값(주입 상태)을 기준선으로
            }
            hasLoaded = true
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            presentError(error)
        }
    }

    func saveDraft() async {
        state.isSaving = true
        defer { state.isSaving = false }

        do {
            try await saveUseCase.execute(draft: state.draft)
            state.shouldDismiss = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension NovelReviewViewModel {

    /// 도메인/Repository 에러를 사용자 메시지로 변환한다. (`handle(_:)`과 이름이 겹치지 않게 분리)
    ///
    /// 매력 포인트 초과(`tooManyAttractivePoints`)만 사용자가 정상적으로 마주칠 수 있는 검증 에러다.
    /// 그 외(네트워크/인증/서버/기간/평점)는 UI·도메인 가드가 이미 막고 있어 **원래 도달하면 안 되는** 경로이므로,
    /// 사용자에겐 일반 문구만 보여주고 원인은 로그로 남겨 추적한다.
    func presentError(_ error: Error) {
        if state.presentedError != nil { return } 
        switch error {
        case NovelReviewDraft.ValidationError.tooManyAttractivePoints(let max):
            state.presentedError = .attractivePointLimit(max: max)
        default:
            logger?.error("NovelReview 예기치 못한 에러: \(String(describing: error))")
            state.presentedError = .unknown
        }
    }
}
