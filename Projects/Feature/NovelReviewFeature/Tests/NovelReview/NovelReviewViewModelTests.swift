//
//  NovelReviewViewModelTests.swift
//  NovelReviewFeature
//
//  Created by Codex on 6/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain
import NovelReviewDomain
import NovelReviewDomainTesting
@testable import NovelReviewFeature

@MainActor
@Suite("NovelReviewViewModel")
struct NovelReviewViewModelTests {

    // MARK: - requestClose

    @Test("로드 중 닫기를 요청하면 로드 완료를 기다리지 않고 닫기 신호를 보낸다")
    func requestCloseDuringLoadDismissesImmediately() async {
        let loadUseCase = SuspendedLoadNovelReviewDraftUseCase()
        let sut = makeViewModel(loadUseCase: loadUseCase)

        sut.handle(.load)
        await loadUseCase.waitUntilStarted()
        sut.handle(.requestClose)

        #expect(sut.state.shouldDismiss)
        #expect(!sut.state.isStopAlertPresented)

        loadUseCase.complete(with: nil)
        await yieldMainActor()
    }

    @Test("닫기 요청 이후 늦게 도착한 로드 결과는 draft를 덮어쓰지 않는다")
    func lateLoadResultAfterCloseDoesNotOverwriteDraft() async {
        let loadUseCase = SuspendedLoadNovelReviewDraftUseCase()
        let sut = makeViewModel(loadUseCase: loadUseCase)
        let initialDraft = sut.state.draft
        let loadedDraft = makeDraft(status: .watched, attractivePoints: [.character])

        sut.handle(.load)
        await loadUseCase.waitUntilStarted()
        sut.handle(.requestClose)
        loadUseCase.complete(with: loadedDraft)
        await yieldMainActor()

        #expect(sut.state.draft == initialDraft)
        #expect(sut.state.shouldDismiss)
    }

    @Test("변경사항이 있으면 닫기 요청 시 화면을 닫지 않고 중단 알럿을 띄운다")
    func requestCloseWithUnsavedChangesPresentsStopAlert() {
        let sut = makeViewModel()

        sut.handle(.updateRating(3.0))
        sut.handle(.requestClose)

        #expect(sut.state.isStopAlertPresented)
        #expect(!sut.state.shouldDismiss)
    }

    // MARK: - Stop alert

    @Test("중단 알럿에서 그만하기를 선택하면 알럿을 닫고 닫기 신호를 보낸다")
    func confirmStopDismissesAlertAndScreen() {
        let sut = makeViewModel()

        sut.handle(.updateRating(3.0))
        sut.handle(.requestClose)
        sut.handle(.confirmStop)

        #expect(!sut.state.isStopAlertPresented)
        #expect(sut.state.shouldDismiss)
    }

    @Test("중단 알럿에서 계속 작성을 선택하면 알럿만 닫고 화면에 머무른다")
    func keepWritingDismissesOnlyAlert() {
        let sut = makeViewModel()

        sut.handle(.updateRating(3.0))
        sut.handle(.requestClose)
        sut.handle(.keepWriting)

        #expect(!sut.state.isStopAlertPresented)
        #expect(!sut.state.shouldDismiss)
    }
}

private extension NovelReviewViewModelTests {
    func makeViewModel(
        status: ReadingStatus = .watching,
        loadUseCase: LoadNovelReviewDraftUseCase = MockLoadNovelReviewDraftUseCase()
    ) -> NovelReviewViewModel {
        NovelReviewViewModel(
            novelID: NovelID(1),
            status: status,
            loadUseCase: loadUseCase,
            saveUseCase: MockSaveNovelReviewUseCase(),
            appReviewUseCase: StubAppReviewRequestUseCase()
        )
    }

    func makeDraft(
        status: ReadingStatus = .watching,
        attractivePoints: [AttractivePoint] = []
    ) -> NovelReviewDraft {
        NovelReviewDraft(
            novelID: NovelID(1),
            status: status,
            attractivePoints: attractivePoints
        )
    }

    func yieldMainActor() async {
        await Task.yield()
        await Task.yield()
    }
}

// 비동기 경합 검증 전용 fake — "실행을 멈춰 세운 뒤 원할 때 완료"시키는 특수 동작이라
// 공유 Mock(MockLoadNovelReviewDraftUseCase)으로는 대체되지 않아 이 파일에 남긴다.
private final class SuspendedLoadNovelReviewDraftUseCase: LoadNovelReviewDraftUseCase {
    private var resultContinuation: CheckedContinuation<NovelReviewDraft?, Never>?
    private var startContinuation: CheckedContinuation<Void, Never>?

    func execute(novelID: NovelID) async throws(RepositoryError) -> NovelReviewDraft? {
        await withCheckedContinuation { continuation in
            resultContinuation = continuation
            startContinuation?.resume()
            startContinuation = nil
        }
    }

    func waitUntilStarted() async {
        guard resultContinuation == nil else { return }

        await withCheckedContinuation { continuation in
            startContinuation = continuation
        }
    }

    func complete(with result: NovelReviewDraft?) {
        resultContinuation?.resume(returning: result)
        resultContinuation = nil
    }
}

// 이 테스트들은 저장 성공 경로를 검증하지 않으므로(닫기/알럿 흐름 전용) 리뷰 게이트는 no-op 스텁으로 둔다.
private struct StubAppReviewRequestUseCase: AppReviewRequestUseCase {
    func recordEngagement() {}
    func shouldRequestReview() -> Bool { false }
    func markReviewRequested() {}
}
