//
//  BootstrapAppUseCaseTests.swift
//  SplashDomainTests
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import SplashDomain
import SplashDomainTesting
import BaseDomain

@Suite
struct BootstrapAppUseCaseTests {

    // MARK: - 강제 업데이트 게이트

    @Test("최소 버전 미달이면 forceUpdate를 반환해 진입을 차단한다")
    func forceUpdateBlocksEntry() async {
        let gate = MockLaunchGateRepository()
        gate.checkForceUpdateRequiredResult = .success(true)
        let sut = makeSUT(gate: gate)

        let outcome = await sut.execute()

        #expect(outcome == .forceUpdate)
    }

    @Test("강제 업데이트 조회가 실패하면 차단하지 않고 통과시킨다")
    func forceUpdateCheckFailurePassesThrough() async {
        let gate = MockLaunchGateRepository()
        gate.checkForceUpdateRequiredResult = .failure(.serverUnavailable)
        let sut = makeSUT(gate: gate)

        let outcome = await sut.execute()

        #expect(outcome == .main(needsTermsAgreement: false))
    }

    @Test("세션이 없어도 최소 버전 미달이면 forceUpdate가 우선한다")
    func forceUpdateTakesPrecedenceOverNoSession() async {
        let gate = MockLaunchGateRepository()
        gate.hasValidSessionReturnValue = false
        gate.checkForceUpdateRequiredResult = .success(true)
        let sut = makeSUT(gate: gate)

        let outcome = await sut.execute()

        #expect(outcome == .forceUpdate)
    }

    @Test("강제 업데이트로 차단되면 부수 태스크를 시작하지 않는다")
    func forceUpdateSkipsLaunchTasks() async {
        let gate = MockLaunchGateRepository()
        gate.checkForceUpdateRequiredResult = .success(true)
        let spy = BackgroundWorkSpy()
        let sut = makeSUT(gate: gate, spy: spy)

        _ = await sut.execute()

        #expect(spy.capturedCount == 0)
    }

    // MARK: - 세션 게이트

    @Test("세션이 없으면 intro를 반환한다")
    func noSessionRoutesToIntro() async {
        let gate = MockLaunchGateRepository()
        gate.hasValidSessionReturnValue = false
        let sut = makeSUT(gate: gate)

        let outcome = await sut.execute()

        #expect(outcome == .intro)
    }

    @Test("세션이 없으면 부수 태스크를 하나도 시작하지 않는다")
    func noSessionSkipsLaunchTasks() async {
        let gate = MockLaunchGateRepository()
        gate.hasValidSessionReturnValue = false
        let spy = BackgroundWorkSpy()
        let sut = makeSUT(gate: gate, spy: spy)

        _ = await sut.execute()

        #expect(spy.capturedCount == 0)
    }

    @Test("세션이 없으면 약관을 조회하지 않는다")
    func noSessionSkipsTermsCheck() async {
        let gate = MockLaunchGateRepository()
        gate.hasValidSessionReturnValue = false
        let sut = makeSUT(gate: gate)

        _ = await sut.execute()

        #expect(gate.isRequiredTermsAgreedCallCount == 0)
    }

    // MARK: - 약관 게이트

    @Test("필수 약관에 모두 동의한 유저는 약관 시트 없이 main으로 진입한다")
    func allTermsAgreedEntersMainWithoutSheet() async {
        let gate = MockLaunchGateRepository()
        gate.isRequiredTermsAgreedResult = .success(true)
        let sut = makeSUT(gate: gate)

        let outcome = await sut.execute()

        #expect(outcome == .main(needsTermsAgreement: false))
    }

    @Test("필수 약관 미동의 유저는 main 진입 시 약관 시트를 함께 띄운다")
    func unagreedTermsEntersMainWithSheet() async {
        let gate = MockLaunchGateRepository()
        gate.isRequiredTermsAgreedResult = .success(false)
        let sut = makeSUT(gate: gate)

        let outcome = await sut.execute()

        #expect(outcome == .main(needsTermsAgreement: true))
    }

    @Test("약관 조회가 실패하면 동의로 간주해 진입을 막지 않는다")
    func termsCheckFailureIsTreatedAsAgreed() async {
        let gate = MockLaunchGateRepository()
        gate.isRequiredTermsAgreedResult = .failure(.networkUnavailable)
        let sut = makeSUT(gate: gate)

        let outcome = await sut.execute()

        #expect(outcome == .main(needsTermsAgreement: false))
    }

    // MARK: - 게이트 예산 (응답이 오지 않는 망)

    // "조회 실패는 통과" 정책은 에러가 돌아와야 작동한다 — 응답 자체가 안 오면
    // URLSession 기본 타임아웃(60초)에 걸릴 때까지 스플래시가 잠기므로 예산으로 끊는다.
    @Test("강제 업데이트 조회가 예산을 넘기면 차단하지 않고 통과시킨다")
    func forceUpdateBudgetExpiryPassesThrough() async {
        // 게이트는 끝내 "차단"이라 답할 참이지만, 예산이 먼저 끝나 그 답은 쓰이지 않는다.
        let gate = HangingLaunchGateRepository(hangsForceUpdate: true, forceUpdateRequired: true)
        let sut = makeSUT(gate: gate, waitGateBudget: { _ in })

        let outcome = await sut.execute()

        #expect(outcome == .main(needsTermsAgreement: false))
    }

    @Test("약관 조회가 예산을 넘겨도 진입을 막지 않는다")
    func termsBudgetExpiryEntersMain() async {
        let gate = HangingLaunchGateRepository(hangsTerms: true)
        let sut = makeSUT(gate: gate, waitGateBudget: { _ in })

        let outcome = await sut.execute()

        #expect(outcome == .main(needsTermsAgreement: false))
    }

    // 예산은 게이트당이 아니라 부트스트랩 전체에 하나다 — 이미 소진됐으면
    // 남은 게이트는 조회를 시작조차 하지 않고 "판정 불가 → 통과"로 떨어져야 한다.
    @Test("예산이 소진되면 남은 게이트는 조회 없이 통과시킨다")
    func exhaustedBudgetSkipsRemainingGates() async {
        let gate = MockLaunchGateRepository()
        gate.checkForceUpdateRequiredResult = .success(true)   // 조회됐다면 forceUpdate로 차단됐을 값
        let sut = makeSUT(gate: gate, gateBudget: .zero)

        let outcome = await sut.execute()

        #expect(outcome == .main(needsTermsAgreement: false))
        #expect(gate.checkForceUpdateRequiredCallCount == 0)
        #expect(gate.isRequiredTermsAgreedCallCount == 0)
    }

    // MARK: - 세션 소실

    @Test("약관 조회가 세션 소실로 실패하면 intro로 보낸다")
    func termsAuthenticationFailureRoutesToIntro() async {
        let gate = MockLaunchGateRepository()
        gate.isRequiredTermsAgreedResult = .failure(.authenticationRequired)
        let sut = makeSUT(gate: gate)

        let outcome = await sut.execute()

        #expect(outcome == .intro)
    }

    @Test("강제 업데이트 조회가 실패해도 세션이 없으면 intro다")
    func forceUpdateFailureWithNoSessionRoutesToIntro() async {
        let gate = MockLaunchGateRepository()
        gate.checkForceUpdateRequiredResult = .failure(.serverUnavailable)
        gate.hasValidSessionReturnValue = false
        let sut = makeSUT(gate: gate)

        let outcome = await sut.execute()

        #expect(outcome == .intro)
    }

    // MARK: - 부수 태스크 (fire-and-forget)

    @Test("세션이 있으면 부수 태스크 4종을 모두 시작한다")
    func sessionStartsAllLaunchTasks() async {
        let task = MockLaunchTaskRepository()
        let spy = BackgroundWorkSpy()
        let sut = makeSUT(task: task, spy: spy)

        _ = await sut.execute()
        await spy.runAll()

        #expect(task.syncUserBasicInfoCallCount == 1)
        #expect(task.registerDeviceTokenIfNeededCallCount == 1)
        #expect(task.syncKeywordsCallCount == 1)
        #expect(task.prefetchHomeDataCallCount == 1)
    }

    @Test("부수 태스크가 끝나지 않아도 게이트 판정이 끝나면 결과를 반환한다")
    func returnsWithoutWaitingForLaunchTasks() async {
        let task = MockLaunchTaskRepository()
        let spy = BackgroundWorkSpy()   // 붙잡기만 하고 실행하지 않는다 = 태스크가 영원히 안 끝나는 상황
        let sut = makeSUT(task: task, spy: spy)

        let outcome = await sut.execute()

        #expect(outcome == .main(needsTermsAgreement: false))
        #expect(task.syncUserBasicInfoCallCount == 0)
        #expect(task.prefetchHomeDataCallCount == 0)
    }

    @Test("부수 태스크가 전부 실패해도 main 진입 결과는 바뀌지 않는다")
    func launchTaskFailuresDoNotAffectOutcome() async {
        let task = MockLaunchTaskRepository()
        task.syncUserBasicInfoResult = .failure(.serverUnavailable)
        task.registerDeviceTokenIfNeededResult = .failure(.unknown)
        let spy = BackgroundWorkSpy()
        let sut = makeSUT(task: task, spy: spy)

        let outcome = await sut.execute()
        await spy.runAll()

        #expect(outcome == .main(needsTermsAgreement: false))
    }
}

// MARK: - Helper

extension BootstrapAppUseCaseTests {

    private func makeSUT(
        gate: LaunchGateRepository = MockLaunchGateRepository(),
        task: MockLaunchTaskRepository = MockLaunchTaskRepository(),
        spy: BackgroundWorkSpy = BackgroundWorkSpy(),
        gateBudget: Duration = DefaultBootstrapAppUseCase.defaultGateBudget,
        waitGateBudget: (@Sendable (Duration) async -> Void)? = nil
    ) -> DefaultBootstrapAppUseCase {
        // 예산 시임을 안 주면 프로덕션 기본값(실제 타이머)을 쓴다 — 게이트가 즉시 답하는
        // 대부분의 테스트에서는 게이트가 레이스를 이기고 타이머는 취소되므로 실시간 대기가 없다.
        if let waitGateBudget {
            return DefaultBootstrapAppUseCase(
                gateRepository: gate,
                taskRepository: task,
                gateBudget: gateBudget,
                launchInBackground: { spy.capture($0) },
                waitGateBudget: waitGateBudget
            )
        }
        return DefaultBootstrapAppUseCase(
            gateRepository: gate,
            taskRepository: task,
            gateBudget: gateBudget,
            launchInBackground: { spy.capture($0) }
        )
    }
}

/// `launchInBackground` 시임에 꽂는 스파이 — 던져진 작업을 붙잡아 두고,
/// 테스트가 `runAll()`을 부를 때만 실행해 fire-and-forget을 결정적으로 검증한다.
private final class BackgroundWorkSpy: @unchecked Sendable {
    private let lock = NSLock()
    private var works: [@Sendable () async -> Void] = []

    var capturedCount: Int {
        lock.withLock { works.count }
    }

    func capture(_ work: @escaping @Sendable () async -> Void) {
        lock.withLock { works.append(work) }
    }

    func runAll() async {
        for work in lock.withLock({ works }) {
            await work()
        }
    }
}

/// 응답이 영영 오지 않는 망을 재현하는 게이트 — 즉시 만료되는 예산 시임과 짝지어
/// 타임아웃 경로를 **실시간 대기 없이** 태운다.
///
/// `Task.sleep`은 취소에 반응하므로, 예산이 레이스를 이겨 그룹이 취소되면 즉시 풀린다 —
/// 그래서 이 fake는 테스트를 행(hang)에 빠뜨리지 않는다(취소를 무시하는 continuation이면 그렇게 된다).
private final class HangingLaunchGateRepository: LaunchGateRepository, @unchecked Sendable {

    private let hangsForceUpdate: Bool
    private let forceUpdateRequired: Bool
    private let hangsTerms: Bool
    private let termsAgreed: Bool

    init(
        hangsForceUpdate: Bool = false,
        forceUpdateRequired: Bool = false,
        hangsTerms: Bool = false,
        termsAgreed: Bool = true
    ) {
        self.hangsForceUpdate = hangsForceUpdate
        self.forceUpdateRequired = forceUpdateRequired
        self.hangsTerms = hangsTerms
        self.termsAgreed = termsAgreed
    }

    func hasValidSession() -> Bool { true }

    func checkForceUpdateRequired() async throws(RepositoryError) -> Bool {
        if hangsForceUpdate { await hang() }
        return forceUpdateRequired
    }

    func isRequiredTermsAgreed() async throws(RepositoryError) -> Bool {
        if hangsTerms { await hang() }
        return termsAgreed
    }

    private func hang() async {
        try? await Task.sleep(for: .seconds(60))
    }
}
