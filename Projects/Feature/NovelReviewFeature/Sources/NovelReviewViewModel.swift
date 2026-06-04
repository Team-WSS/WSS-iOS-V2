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

protocol NovelReviewViewModelInput {
    func load()
    func selectStatus(_ status: ReadingStatus)
    func updatePeriod(start: Date?, end: Date?)
    func toggleAttractivePoint(_ point: AttractivePoint)
    func save()
    func dismissError()
}

protocol NovelReviewViewModelOutput: ObservableObject {
    var selectedStatus: ReadingStatus { get }
    var selectedPeriod: ReadingPeriod? { get }
    var selectedAttractivePoints: [AttractivePoint] { get }
    var isLoading: Bool { get }
    var isSaving: Bool { get }
    var shouldDismiss: Bool { get }
    var errorMessage: String? { get }
}

typealias NovelReviewViewModel = NovelReviewViewModelInput & NovelReviewViewModelOutput

@MainActor
final class DefaultNovelReviewViewModel: NovelReviewViewModel {

    // MARK: - State

    @Published private var draft: NovelReviewDraft
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var shouldDismiss = false
    @Published private(set) var errorMessage: String?

    // MARK: - Output

    var selectedStatus: ReadingStatus { draft.status }
    var selectedPeriod: ReadingPeriod? { draft.period }
    var selectedAttractivePoints: [AttractivePoint] { draft.attractivePoints }

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
        self.draft = NovelReviewDraft(novelID: novelID, status: .watching)
        self.loadUseCase = loadUseCase
        self.saveUseCase = saveUseCase
    }
}

// MARK: - Input

extension DefaultNovelReviewViewModel {

    /// 화면 진입 시 기존 초안을 불러온다. 초안이 없으면(nil) 기본 draft를 유지한다.
    func load() {
        guard !isLoading else { return }
        Task { await loadDraft() }
    }

    /// 읽기 상태 선택. ReadingStatus는 단일 값이라 새 값으로 바꾸면 기존 선택은 자동 해제된다.
    /// 상태를 바꾸면 도메인이 기존 기간을 새 상태에 맞게 normalize한다(예: watched→watching 시 종료일 제거).
    func selectStatus(_ status: ReadingStatus) {
        draft.changeStatus(status)
    }

    /// 독서 기간 설정. 상태별 유효 날짜(watching=시작, watched=시작+종료, quit=종료)는
    /// 도메인 `ReadingPeriod.normalized(for:)`가 강제한다. ViewModel은 입력 날짜로 `ReadingPeriod`를 만들어 위임만 한다.
    /// 둘 다 nil이거나 시작>종료면 도메인이 throw → 사용자 메시지로 변환.
    func updatePeriod(start: Date?, end: Date?) {
        guard start != nil || end != nil else {
            draft.setPeriod(nil)
            return
        }
        do {
            let period = try ReadingPeriod(start: start, end: end)
            draft.setPeriod(period)
        } catch {
            handle(error: error)
        }
    }

    /// 매력 포인트 토글. 이미 선택돼 있으면 해제, 아니면 추가한다.
    /// 추가 시 최대 개수(3) 정책은 도메인(`NovelReviewDraft`)이 검증하며, 초과 시 throw → 사용자 메시지로 변환.
    func toggleAttractivePoint(_ point: AttractivePoint) {
        do {
            if draft.attractivePoints.contains(point) {
                draft.removeAttractivePoint(point)
            } else {
                try draft.addAttractivePoint(point)
            }
        } catch {
            handle(error: error)
        }
    }

    /// 완료 버튼. 현재 draft를 저장하고, 성공하면 화면을 닫도록 신호한다.
    func save() {
        guard !isSaving else { return }
        Task { await saveDraft() }
    }

    func dismissError() {
        errorMessage = nil
    }
}

// MARK: - Async Work

private extension DefaultNovelReviewViewModel {

    func loadDraft() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let loaded = try await loadUseCase.execute(novelID: novelID) {
                draft = loaded
            }
        } catch {
            handle(error: error)
        }
    }

    func saveDraft() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await saveUseCase.execute(draft: draft)
            shouldDismiss = true
        } catch {
            handle(error: error)
        }
    }
}

// MARK: - Error Mapping

private extension DefaultNovelReviewViewModel {
    func handle(error: Error) {
        switch error {
        case RepositoryError.networkUnavailable:
            errorMessage = "네트워크 연결을 확인해 주세요"
        case RepositoryError.authenticationRequired:
            errorMessage = "로그인이 필요해요"
        case RepositoryError.serverUnavailable:
            errorMessage = "서버에 잠시 문제가 있어요"
        case RepositoryError.notFound:
            errorMessage = "평가 정보를 찾을 수 없어요"
        case NovelReviewDraft.ValidationError.tooManyAttractivePoints(let max):
            errorMessage = "매력 포인트는 최대 \(max)개까지 선택할 수 있어요"
        case ReadingPeriod.ValidationError.startAfterEnd:
            errorMessage = "시작일은 종료일보다 늦을 수 없어요"
        default:
            errorMessage = "잠시 후 다시 시도해 주세요"
        }
    }
}
