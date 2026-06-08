//
//  NovelReviewViewModel.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import NovelReviewDomain

@MainActor
final class NovelReviewViewModel: ObservableObject {

    // MARK: - State

    struct State {
        /// 도메인 엔티티를 그대로 보유(표현값 소스). View가 `state.draft.…`로 직접 읽는다.
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

    // MARK: - Init

    init(
        novelID: NovelID,
        loadUseCase: LoadNovelReviewDraftUseCase,
        saveUseCase: SaveNovelReviewUseCase
    ) {
        self.novelID = novelID
        self.state = State(draft: NovelReviewDraft(novelID: novelID, status: .watching))
        self.loadUseCase = loadUseCase
        self.saveUseCase = saveUseCase
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .selectStatus(let status):
            // ReadingStatus는 단일 값이라 새 값으로 바꾸면 기존 선택은 자동 해제된다.
            // 상태를 바꾸면 도메인이 기존 기간을 새 상태에 맞게 normalize한다(예: watched→watching 시 종료일 제거).
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

    /// 화면 진입 시 기존 초안을 불러온다. 초안이 없으면(nil) 기본 draft를 유지한다.
    /// 최초 1회만 수행한다(재진입 시 편집 중 덮어쓰기 방지). 실패하면 다음 진입에 재시도 가능.
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
    func presentError(_ error: Error) {
        switch error {
        case RepositoryError.networkUnavailable:
            state.errorMessage = "네트워크 연결을 확인해 주세요"
        case RepositoryError.authenticationRequired:
            state.errorMessage = "로그인이 필요해요"
        case RepositoryError.serverUnavailable:
            state.errorMessage = "서버에 잠시 문제가 있어요"
        case RepositoryError.notFound:
            state.errorMessage = "평가 정보를 찾을 수 없어요"
        case NovelReviewDraft.ValidationError.tooManyAttractivePoints(let max):
            state.errorMessage = "매력 포인트는 최대 \(max)개까지 선택할 수 있어요"
        case ReadingPeriod.ValidationError.startAfterEnd:
            state.errorMessage = "시작일은 종료일보다 늦을 수 없어요"
        case Rating.ValidationError.outOfRange, Rating.ValidationError.invalidStep:
            state.errorMessage = "평점은 0.5~5.0 사이에서 0.5 단위로 줄 수 있어요"
        default:
            state.errorMessage = "잠시 후 다시 시도해 주세요"
        }
    }
}
