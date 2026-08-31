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

/// 스플래시 **화면의 계약** 명세 — 부트스트랩 정책 자체는 `BootstrapAppUseCaseTests`(SplashDomain)가
/// 명세하고, 이 화면은 그 결과를 **언제 알리는지**만 책임진다:
/// load 1회 → 부트스트랩과 최소 노출 타이머(1초)를 **병렬**로 → **둘 다** 끝나야 `state.outcome` 노출
/// (View가 이를 onFinish 콜백으로 App에 올리고, 화면 전환은 App 몫).
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
        let displayStarted = await display.waitUntilStarted(within: .seconds(5))
        #expect(displayStarted)
        guard displayStarted else { return }
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
        let bootstrapStarted = await useCase.waitUntilStarted(within: .seconds(5))
        #expect(bootstrapStarted)
        guard bootstrapStarted else { return }
        await yieldMainActor()

        #expect(sut.state.outcome == nil)

        useCase.complete(with: .intro)
        await sut.bootstrapTask?.value

        #expect(sut.state.outcome == .intro)
    }

    // 위 두 테스트는 한쪽만 매달아서, 직렬 구현(`await execute()` 다음 `await wait()`)으로 바꿔도
    // 전부 통과한다 — 계약("병렬로 돌려 둘 다 끝나야 완료")을 잡는 그물은 이 테스트다.
    @Test("부트스트랩과 최소 노출 타이머를 동시에 시작한다")
    func startsBootstrapAndMinimumDisplayTogether() async {
        let useCase = SuspendedBootstrapAppUseCase()
        let display = SuspendedMinimumDisplay()
        let sut = makeViewModel(
            useCase: useCase,
            waitMinimumDisplayTime: { await display.wait() }
        )

        sut.handle(.load)

        // 부트스트랩을 매달아 둔 채로 타이머도 시작돼 있어야 병렬이다.
        // 직렬이면 둘 중 하나가 영영 시작되지 않아 `false`로 떨어진다(행이 아니라 실패로).
        let bootstrapStarted = await useCase.waitUntilStarted(within: .seconds(5))
        let displayStarted = await display.waitUntilStarted(within: .seconds(5))

        #expect(bootstrapStarted)
        #expect(displayStarted)

        // 둘 다 시작됐을 때만 완료 경로로 넘어간다 — 직렬 구현이면 위 단언이 이미 실패했고,
        // 시작조차 안 된 쪽을 `complete()`해도 풀 continuation이 없어 아래 `bootstrapTask` 대기가
        // 영원히 매달린다(실측: 테스트가 실패 대신 행으로 굳어 CI를 막는다).
        guard bootstrapStarted, displayStarted else { return }

        #expect(sut.state.outcome == nil)

        useCase.complete(with: .forceUpdate)
        display.complete()
        await sut.bootstrapTask?.value

        #expect(sut.state.outcome == .forceUpdate)
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
        await waitForStart(lock: lock, isStarted: { self.hasStarted }, store: {
            // 덮어쓰면 앞 대기자가 영원히 resume되지 않아 조용히 행이 된다 — 행 대신 즉시 드러나게 한다.
            precondition(self.startContinuation == nil, "시작 대기자는 한 번에 하나만 지원한다")
            self.startContinuation = $0
        }, take: {
            defer { self.startContinuation = nil }
            return self.startContinuation
        })
    }

    /// 시작 신호를 상한 안에서 기다린다 — 신호가 끝내 오지 않을 수 있는 검증(병렬 시작)에서
    /// 테스트가 행에 빠져 CI를 막는 대신 `false`로 떨어지게 한다.
    func waitUntilStarted(within timeout: Duration) async -> Bool {
        await raceStart(timeout: timeout) { await self.waitUntilStarted() }
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
        await waitForStart(lock: lock, isStarted: { self.hasStarted }, store: {
            // 덮어쓰면 앞 대기자가 영원히 resume되지 않아 조용히 행이 된다 — 행 대신 즉시 드러나게 한다.
            precondition(self.startContinuation == nil, "시작 대기자는 한 번에 하나만 지원한다")
            self.startContinuation = $0
        }, take: {
            defer { self.startContinuation = nil }
            return self.startContinuation
        })
    }

    func waitUntilStarted(within timeout: Duration) async -> Bool {
        await raceStart(timeout: timeout) { await self.waitUntilStarted() }
    }

    func complete() {
        let pendingDisplay = lock.withLock {
            defer { displayContinuation = nil }
            return displayContinuation
        }
        pendingDisplay?.resume()
    }
}

// MARK: - 두 fake가 공유하는 시작 대기

/// 시작 신호를 기다린다. **취소에 반응한다** — 상한을 건 래퍼(`raceStart`)가 진 쪽 태스크를 취소했을 때
/// 이 대기가 안 풀리면 task group이 종료를 못 기다려 결국 행이 되기 때문이다.
private func waitForStart(
    lock: NSLock,
    isStarted: @escaping () -> Bool,
    store: @escaping (CheckedContinuation<Void, Never>) -> Void,
    take: @escaping () -> CheckedContinuation<Void, Never>?
) async {
    await withTaskCancellationHandler {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let alreadyStarted = lock.withLock {
                if isStarted() { return true }
                store(continuation)
                return false
            }

            if alreadyStarted {
                continuation.resume()
            } else if Task.isCancelled {
                // 등록 전에 취소가 지나갔으면 onCancel이 우리를 못 봤다 — 직접 회수해 푼다.
                // `take`가 nil로 비우므로 onCancel·execute와 이중 resume이 나지 않는다.
                lock.withLock { take() }?.resume()
            }
        }
    } onCancel: {
        lock.withLock { take() }?.resume()
    }
}

/// 시작 대기와 타이머를 레이스시켜, 신호가 오면 `true` 상한을 넘기면 `false`를 준다.
private func raceStart(timeout: Duration, _ waitUntilStarted: @escaping @Sendable () async -> Void) async -> Bool {
    await withTaskGroup(of: Bool.self) { group in
        group.addTask {
            await waitUntilStarted()
            return true
        }
        group.addTask {
            try? await Task.sleep(for: timeout)
            return false
        }

        let first = await group.next() ?? false
        group.cancelAll()
        return first
    }
}
