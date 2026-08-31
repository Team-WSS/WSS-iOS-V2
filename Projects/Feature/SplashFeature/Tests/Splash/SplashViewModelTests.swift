//
//  SplashViewModelTests.swift
//  SplashFeature
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import SplashDomain
import SplashDomainTesting
@testable import SplashFeature

@MainActor
@Suite("SplashViewModel")
struct SplashViewModelTests {

    // MARK: - 부트스트랩 실행

    @Test("load 액션은 부트스트랩을 실행한다")
    func loadExecutesBootstrap() async {
        let useCase = MockBootstrapAppUseCase()
        let sut = makeViewModel(useCase: useCase)

        sut.handle(.load)
        await sut.bootstrapTask?.value

        #expect(useCase.executeCallCount == 1)
    }

    @Test("부트스트랩 결과를 outcome으로 노출한다")
    func exposesBootstrapOutcome() async {
        let useCase = MockBootstrapAppUseCase()
        useCase.executeResult = .forceUpdate
        let sut = makeViewModel(useCase: useCase)

        sut.handle(.load)
        await sut.bootstrapTask?.value

        #expect(sut.state.outcome == .forceUpdate)
    }

    @Test("load가 중복 발화해도 부트스트랩은 한 번만 실행한다")
    func duplicateLoadRunsBootstrapOnce() async {
        let useCase = MockBootstrapAppUseCase()
        let sut = makeViewModel(useCase: useCase)

        sut.handle(.load)
        sut.handle(.load)
        await sut.bootstrapTask?.value

        #expect(useCase.executeCallCount == 1)
    }

    // MARK: - 완료 조건 (부트스트랩 ∧ 최소 노출 시간)

    @Test("부트스트랩이 끝나도 최소 노출 시간이 지나기 전에는 완료를 알리지 않는다")
    func holdsOutcomeUntilMinimumDisplayTimePasses() async {
        let display = SuspendedMinimumDisplay()
        let sut = makeViewModel(
            useCase: MockBootstrapAppUseCase(),
            waitMinimumDisplayTime: { await display.wait() }
        )

        sut.handle(.load)
        await display.waitUntilStarted()
        await yieldMainActor()

        #expect(sut.state.outcome == nil)

        display.complete()
        await sut.bootstrapTask?.value

        #expect(sut.state.outcome != nil)
    }

    @Test("최소 노출 시간이 지나도 부트스트랩이 끝나기 전에는 완료를 알리지 않는다")
    func holdsOutcomeUntilBootstrapFinishes() async {
        let useCase = SuspendedBootstrapAppUseCase()
        let sut = makeViewModel(useCase: useCase)

        sut.handle(.load)
        await useCase.waitUntilStarted()
        await yieldMainActor()

        #expect(sut.state.outcome == nil)

        useCase.complete(with: .intro)
        await sut.bootstrapTask?.value

        #expect(sut.state.outcome == .intro)
    }
}

// MARK: - Helper

private extension SplashViewModelTests {

    func makeViewModel(
        useCase: BootstrapAppUseCase = MockBootstrapAppUseCase(),
        waitMinimumDisplayTime: @escaping @Sendable () async -> Void = {}
    ) -> SplashViewModel {
        SplashViewModel(
            bootstrapAppUseCase: useCase,
            waitMinimumDisplayTime: waitMinimumDisplayTime
        )
    }

    func yieldMainActor() async {
        await Task.yield()
        await Task.yield()
        await Task.yield()
    }
}

// 비동기 경합 검증 전용 fake — "실행을 멈춰 세운 뒤 원할 때 완료"시키는 특수 동작이라
// 공유 Mock(MockBootstrapAppUseCase)으로는 대체되지 않아 이 파일에 남긴다.
private final class SuspendedBootstrapAppUseCase: BootstrapAppUseCase, @unchecked Sendable {
    private var resultContinuation: CheckedContinuation<BootstrapOutcome, Never>?
    private var startContinuation: CheckedContinuation<Void, Never>?

    func execute() async -> BootstrapOutcome {
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

    func complete(with outcome: BootstrapOutcome) {
        resultContinuation?.resume(returning: outcome)
        resultContinuation = nil
    }
}

// 최소 노출 시간 시임을 붙잡아 두는 fake — 위와 같은 이유로 이 파일 전용.
private final class SuspendedMinimumDisplay: @unchecked Sendable {
    private var displayContinuation: CheckedContinuation<Void, Never>?
    private var startContinuation: CheckedContinuation<Void, Never>?

    func wait() async {
        await withCheckedContinuation { continuation in
            displayContinuation = continuation
            startContinuation?.resume()
            startContinuation = nil
        }
    }

    func waitUntilStarted() async {
        guard displayContinuation == nil else { return }

        await withCheckedContinuation { continuation in
            startContinuation = continuation
        }
    }

    func complete() {
        displayContinuation?.resume()
        displayContinuation = nil
    }
}
