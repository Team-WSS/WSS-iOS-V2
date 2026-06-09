//
//  NovelReviewViewModel.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import Logger
import NovelReviewDomain

@MainActor
final class NovelReviewViewModel: ObservableObject {

    // MARK: - State

    struct State {
        var draft: NovelReviewDraft
        var isLoading = false
        var isSaving = false
        var shouldDismiss = false
        var errorMessage: String?
    }

    // MARK: - Action

    enum Action {
        case load
        case selectStatus(ReadingStatus)
        case updatePeriod(start: Date?, end: Date?)
        case updateRating(Double)
        case toggleAttractivePoint(AttractivePoint)
        case save
        case dismissError
    }

    // MARK: - Output

    @Published private(set) var state: State

    /// 최초 1회만 로드. 화면 재진입(onAppear 재호출) 시 편집 중인 draft를 서버 값으로 덮어쓰지 않기 위함.
    private var hasLoaded = false

    // MARK: - Dependency

    private let novelID: NovelID
    private let loadUseCase: LoadNovelReviewDraftUseCase
    private let saveUseCase: SaveNovelReviewUseCase
    private let logger: Logger?

    // MARK: - Init

    init(
        novelID: NovelID,
        loadUseCase: LoadNovelReviewDraftUseCase,
        saveUseCase: SaveNovelReviewUseCase,
        logger: Logger? = nil
    ) {
        self.novelID = novelID
        self.state = State(draft: NovelReviewDraft(novelID: novelID, status: .watching))
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
        case .dismissError:
            state.errorMessage = nil
        }
    }
}

// MARK: - Action Handling

private extension NovelReviewViewModel {
    func load() {
        guard !hasLoaded, !state.isLoading else { return }
        Task { await loadDraft() }
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
}

// MARK: - Async Work

private extension NovelReviewViewModel {

    func loadDraft() async {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            if let loaded = try await loadUseCase.execute(novelID: novelID) {
                state.draft = loaded
            }
            hasLoaded = true
        } catch {
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
        switch error {
        case NovelReviewDraft.ValidationError.tooManyAttractivePoints(let max):
            state.errorMessage = "매력 포인트는 최대 \(max)개까지 선택할 수 있어요"
        default:
            logger?.error("NovelReview 예기치 못한 에러: \(String(describing: error))")
            state.errorMessage = "알 수 없는 에러가 발생했어요"
        }
    }
}
