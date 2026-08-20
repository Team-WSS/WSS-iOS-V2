//
//  CreateCollectionViewModel.swift
//  CollectionFeature
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import CollectionDomain
import Logger

@MainActor
@Observable
final class CreateCollectionViewModel {

    // MARK: - State

    struct State {
        var draft: CollectionDraft
        /// 작품 리스트 그리드 렌더링 전용 캐시 — `draft.novelIDs`(제출값, `[NovelID]`뿐)와 별개로
        /// 표지·제목을 그리기 위해 필요하다(`CreateFeedViewModel`의 `attachedImageDatas`와 같은 구조).
        /// 채우는 유일한 경로(작품 추가 화면)가 이번 범위 밖이라 지금은 항상 비어있다.
        var novelDisplayInfo: [NovelID: CollectionNovel] = [:]
        var isSubmitting = false
        var shouldDismiss = false
        var requiresAuthentication = false
        var isStopAlertPresented = false
        var presentedError: SubmitError?
    }

    /// 사용자에게 표시할 에러의 의미값. 카피·표현(토스트 타입)은 View가 결정한다.
    enum SubmitError: Equatable {
        case unknown
    }

    // MARK: - Derived

    var canSubmit: Bool { state.draft.isSubmittable && !state.isSubmitting }
    var representativeNovelID: NovelID? { state.draft.effectiveRepresentativeNovelID }

    // MARK: - Action

    enum Action {
        case updateName(String)
        case updateDescription(String)
        case togglePrivate
        case selectRepresentativeNovel(NovelID)
        case submit
        case requestClose
        case confirmStop
        case keepWriting
        case dismissError
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    /// 뒤로가기 시 "그만 작성" 확인 알럿을 띄울지 판단하는 기준선 — 이 화면은 로드가 없는 순수 생성
    /// 화면이라 항상 빈 `CollectionDraft()`다(`NovelReviewViewModel`의 `baselineDraft`와 같은 역할).
    @ObservationIgnored private var baselineDraft: CollectionDraft

    /// View가 직접 보지 않는 내부 판단값이라 Derived가 아니라 Property에 둔다.
    private var hasUnsavedChanges: Bool { state.draft != baselineDraft }

    // MARK: - Dependency

    private let logger: Logger?

    // CollectionDomain
    private let createCollectionUseCase: CreateCollectionUseCase

    // MARK: - Init

    init(
        createCollectionUseCase: CreateCollectionUseCase,
        logger: Logger? = nil
    ) {
        self.createCollectionUseCase = createCollectionUseCase
        self.logger = logger
        let initialDraft = CollectionDraft()
        self.state = State(draft: initialDraft)
        self.baselineDraft = initialDraft
    }

    #if DEBUG
    /// Preview 전용 — 작품 리스트 그리드(대표 배지 포함) 렌더링을 확인하기 위한 시드 경로.
    /// 실제 진입 경로(작품 추가 화면)가 이번 범위 밖이라 그리드가 실제 앱에선 항상 비어있는데, 이
    /// initializer로 Preview에서만 우회해 시각 확인한다 — Factory·프로덕션 코드는 쓰지 않는다.
    init(
        previewDraft: CollectionDraft,
        previewNovelDisplayInfo: [NovelID: CollectionNovel],
        createCollectionUseCase: CreateCollectionUseCase
    ) {
        self.createCollectionUseCase = createCollectionUseCase
        self.logger = nil
        self.state = State(draft: previewDraft, novelDisplayInfo: previewNovelDisplayInfo)
        self.baselineDraft = previewDraft
    }
    #endif

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .updateName(let value):
            updateName(value)
        case .updateDescription(let value):
            updateDescription(value)
        case .togglePrivate:
            state.draft.togglePrivate()
        case .selectRepresentativeNovel(let id):
            selectRepresentativeNovel(id)
        case .submit:
            submit()
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

private extension CreateCollectionViewModel {

    /// 이름 갱신. 20자 초과분은 View(필드)가 로컬에서 이미 잘라 넘기므로(글자수 clamp 트랩,
    /// `Feature/CLAUDE.md` 참고) 여기서 throw가 발생하면 그 클램프가 뚫린 것 — 로그만 남긴다.
    func updateName(_ value: String) {
        do {
            try state.draft.updateName(value)
        } catch {
            logger?.error("CreateCollection 이름 갱신 실패(도달하면 안 되는 경로): \(String(describing: error))")
        }
    }

    /// 설명 갱신. 60자 클램프도 이름과 동일하게 View 쪽에서 먼저 막는다.
    func updateDescription(_ value: String) {
        do {
            try state.draft.updateDescription(value)
        } catch {
            logger?.error("CreateCollection 설명 갱신 실패(도달하면 안 되는 경로): \(String(describing: error))")
        }
    }

    /// 대표 작품 지정. `novelIDs`에 없는 id를 넘기면 도메인이 throw하지만, View는 항상 그리드에 실제로
    /// 표시된(=novelIDs에 있는) 작품의 id만 넘기므로 도달하면 안 되는 경로다.
    func selectRepresentativeNovel(_ id: NovelID) {
        do {
            try state.draft.setRepresentativeNovel(id)
        } catch {
            logger?.error("CreateCollection 대표 작품 지정 실패(도달하면 안 되는 경로): \(String(describing: error))")
        }
    }

    /// 완료 버튼. 제출 가능 여부는 UseCase가 다시 검증하지 않으므로(`CollectionDomain/CLAUDE.md`),
    /// 이 화면이 `canSubmit`으로 잠근다.
    func submit() {
        guard canSubmit else { return }
        Task { await createCollection() }
    }

    /// 뒤로가기 요청. 변경 사항이 없으면 바로 닫고, 있으면 확인 알럿을 띄운다(`NovelReview`/`CreateFeed`와
    /// 동일 패턴, 사용자 확정 #199).
    func requestClose() {
        if hasUnsavedChanges {
            state.isStopAlertPresented = true
        } else {
            state.shouldDismiss = true
        }
    }

    /// "그만하기" 확인. 알럿을 내리고 닫기 신호를 발화한다.
    func confirmStop() {
        state.isStopAlertPresented = false
        state.shouldDismiss = true
    }
}

// MARK: - UseCase Handling

private extension CreateCollectionViewModel {

    func createCollection() async {
        state.isSubmitting = true
        defer { state.isSubmitting = false }

        do {
            _ = try await createCollectionUseCase.execute(state.draft)
            state.shouldDismiss = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension CreateCollectionViewModel {

    func presentError(_ error: Error) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("CreateCollection 예기치 못한 에러: \(String(describing: error))")
        state.presentedError = .unknown
    }

    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
