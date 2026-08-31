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
// continuation 상태는 두 실행 컨텍스트(자식 태스크의 execute vs 테스트의 waitUntilStarted/complete)에서
// 접근되므로 NSLock으로 지킨다 — 락 없이 시작 신호가 유실되면 테스트가 실패 대신 '행'으로 굳는다.
// resume은 재진입을 피해 항상 락 밖에서 호출한다.
private final class SuspendedBootstrapAppUseCase: BootstrapAppUseCase, @unchecked Sendable {
    private let lock = NSLock()
    private var hasStarted = false
    private var resultContinuation: CheckedContinuation<BootstrapOutcome, Never>?
    private var startContinuation: CheckedContinuation<Void, Never>?

    func execute() async -> BootstrapOutcome {
        await withCheckedContinuation { continuation in
            let pendingStart = lock.withLock {
                hasStarted = true
                resultContinuation = continuation
                defer { startContinuation = nil }
                return startContinuation
            }
            pendingStart?.resume()
        }
    }

    func waitUntilStarted() async {
        await withCheckedContinuation { continuation in
            let alreadyStarted = lock.withLock {
                if hasStarted { return true }
                startContinuation = continuation
                return false
            }
            if alreadyStarted { continuation.resume() }
        }
    }

    func complete(with outcome: BootstrapOutcome) {
        let pendingResult = lock.withLock {
            defer { resultContinuation = nil }
            return resultContinuation
        }
        pendingResult?.resume(returning: outcome)
    }
}

// 최소 노출 시간 시임을 붙잡아 두는 fake — 위와 같은 이유(파일 전용·락 보호)로 같은 구조.
private final class SuspendedMinimumDisplay: @unchecked Sendable {
    private let lock = NSLock()
    private var hasStarted = false
    private var displayContinuation: CheckedContinuation<Void, Never>?
    private var startContinuation: CheckedContinuation<Void, Never>?

    func wait() async {
        await withCheckedContinuation { continuation in
            let pendingStart = lock.withLock {
                hasStarted = true
                displayContinuation = continuation
                defer { startContinuation = nil }
                return startContinuation
            }
            pendingStart?.resume()
        }
    }

    func waitUntilStarted() async {
        await withCheckedContinuation { continuation in
            let alreadyStarted = lock.withLock {
                if hasStarted { return true }
                startContinuation = continuation
                return false
            }
            if alreadyStarted { continuation.resume() }
        }
    }

    func complete() {
        let pendingDisplay = lock.withLock {
            defer { displayContinuation = nil }
            return displayContinuation
        }
        pendingDisplay?.resume()
    }
}
