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
        gate: MockLaunchGateRepository = MockLaunchGateRepository(),
        task: MockLaunchTaskRepository = MockLaunchTaskRepository(),
        spy: BackgroundWorkSpy = BackgroundWorkSpy()
    ) -> DefaultBootstrapAppUseCase {
        DefaultBootstrapAppUseCase(
            gateRepository: gate,
            taskRepository: task,
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
