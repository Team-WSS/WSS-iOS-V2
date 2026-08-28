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
        /// "작품 추가" 화면의 확정 결과(`.setNovels`)와, 수정 화면 진입 시 `init`의
        /// `initialNovelDisplayInfo`(원본 컬렉션 작품 목록) 둘 중 하나로 채워진다 — 이 캐시에 없는
        /// id는 `novelIDs`에 있어도 그리드에 그려지지 않는다(`novelListSection` 참고).
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

    /// 생성 화면과 수정 화면을 겸용하기 위한 모드 — `FeedFeature.CreateFeedViewModel`과 동일 패턴.
    /// 두 화면이 폼 UI·검증 로직을 전부 공유하고 진입 초기값·제출 시 호출할 UseCase만 다르다.
    enum Mode {
        case create
        case edit(CollectionID)
    }

    // MARK: - Derived

    /// 수정 모드에서는 원본과 달라진 게 없으면(`hasUnsavedChanges == false`) 완료를 눌러도 보낼 게
    /// 없으므로 비활성화한다(사용자 확정) — 생성 모드는 원래 기준(`isSubmittable`)만 본다.
    var canSubmit: Bool {
        guard state.draft.isSubmittable, !state.isSubmitting else { return false }
        return isEditing ? hasUnsavedChanges : true
    }
    var representativeNovelID: NovelID? { state.draft.effectiveRepresentativeNovelID }

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    // MARK: - Action

    enum Action {
        case updateName(String)
        case updateDescription(String)
        case togglePrivate
        case selectRepresentativeNovel(NovelID)
        case setNovels([CollectionNovel])
        case submit
        case requestClose
        case confirmStop
        case keepWriting
        case dismissError
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    private let mode: Mode

    /// 뒤로가기 시 "그만 작성"/"그만 수정" 확인 알럿을 띄울지 판단하는 기준선. 생성은 항상 빈
    /// `CollectionDraft()`, 수정은 진입 시 서버에서 불러온 원본 값(`initialDraft`)이 기준선이다
    /// (`NovelReviewViewModel`의 `baselineDraft`와 같은 역할).
    @ObservationIgnored private var baselineDraft: CollectionDraft

    /// View가 직접 보지 않는 내부 판단값이라 Derived가 아니라 Property에 둔다.
    private var hasUnsavedChanges: Bool { state.draft != baselineDraft }

    // MARK: - Dependency

    private let logger: Logger?

    // CollectionDomain — 모드에 따라 둘 중 하나만 실제로 쓰인다(`CreateFeedViewModel`과 동일 이유로
    // 옵셔널: 생성 화면 조립 시 update UseCase가, 수정 화면 조립 시 create UseCase가 굳이 필요 없다).
    private let createCollectionUseCase: CreateCollectionUseCase?
    private let updateCollectionUseCase: UpdateCollectionUseCase?

    // MARK: - Init

    /// - Parameters:
    ///   - initialDraft: 생성은 빈 `CollectionDraft()`(기본값), 수정은 `CollectionDraft(from:)`으로
    ///     원본 컬렉션을 편집 가능한 초안으로 되돌린 값을 호출부(`CollectionDetailView`)가 넘긴다.
    ///   - initialNovelDisplayInfo: `initialDraft.novelIDs`에 대응하는 표지·제목 캐시. 그리드는
    ///     `novelIDs`가 아니라 이 딕셔너리를 보고 그린다(`novelListSection` 참고) — 수정 화면 진입
    ///     시 이걸 안 채우면 개수 표시는 맞는데 그리드 셀이 하나도 안 그려진다(실측).
    init(
        mode: Mode = .create,
        createCollectionUseCase: CreateCollectionUseCase? = nil,
        updateCollectionUseCase: UpdateCollectionUseCase? = nil,
        initialDraft: CollectionDraft = CollectionDraft(),
        initialNovelDisplayInfo: [NovelID: CollectionNovel] = [:],
        logger: Logger? = nil
    ) {
        self.mode = mode
        self.createCollectionUseCase = createCollectionUseCase
        self.updateCollectionUseCase = updateCollectionUseCase
        self.logger = logger
        self.state = State(draft: initialDraft, novelDisplayInfo: initialNovelDisplayInfo)
        self.baselineDraft = initialDraft
    }

    #if DEBUG
    /// Preview 전용 — 작품 리스트 그리드(대표 배지 포함) 렌더링을 확인하기 위한 시드 경로.
    /// Factory·프로덕션 코드는 쓰지 않는다.
    init(
        previewDraft: CollectionDraft,
        previewNovelDisplayInfo: [NovelID: CollectionNovel],
        createCollectionUseCase: CreateCollectionUseCase
    ) {
        self.mode = .create
        self.createCollectionUseCase = createCollectionUseCase
        self.updateCollectionUseCase = nil
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
        case .setNovels(let novels):
            setNovels(novels)
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

    /// "작품 추가" 화면이 돌려준 편집 결과 전체 반영. 그 화면이 이미 100개로 막아두므로 여기서 throw가
    /// 발생하면 도달하면 안 되는 경로 — 로그만 남긴다.
    func setNovels(_ novels: [CollectionNovel]) {
        do {
            try state.draft.setNovels(novels.map(\.id))
            state.novelDisplayInfo = Dictionary(uniqueKeysWithValues: novels.map { ($0.id, $0) })
        } catch {
            logger?.error("CreateCollection 작품 리스트 갱신 실패(도달하면 안 되는 경로): \(String(describing: error))")
        }
    }

    /// 완료 버튼. 제출 가능 여부는 UseCase가 다시 검증하지 않으므로(`CollectionDomain/CLAUDE.md`),
    /// 이 화면이 `canSubmit`으로 잠근다.
    func submit() {
        guard canSubmit else { return }
        Task { await submitCollection() }
    }

    /// 뒤로가기 요청. 변경 사항이 없으면 바로 닫고, 있으면 확인 알럿을 띄운다(`NovelReview`/`CreateFeed`와
    /// 동일 패턴, 사용자 확정 #199) — 수정 모드에서도 기준선(`baselineDraft` = 원본 값)과 비교하므로
    /// 같은 판단이 그대로 적용된다.
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

    func submitCollection() async {
        state.isSubmitting = true
        defer { state.isSubmitting = false }

        do {
            switch mode {
            case .create:
                guard let createCollectionUseCase else {
                    logger?.error("CreateCollectionViewModel이 .create 모드인데 createCollectionUseCase가 없다(도달하면 안 되는 경로)")
                    state.presentedError = .unknown
                    return
                }
                _ = try await createCollectionUseCase.execute(state.draft)
            case .edit(let id):
                guard let updateCollectionUseCase else {
                    logger?.error("CreateCollectionViewModel이 .edit 모드인데 updateCollectionUseCase가 없다(도달하면 안 되는 경로)")
                    state.presentedError = .unknown
                    return
                }
                try await updateCollectionUseCase.execute(id: id, draft: state.draft)
            }
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
