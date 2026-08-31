//
//  MockBootstrapAppUseCase.swift
//  SplashDomainTesting
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import SplashDomain

/// Feature ViewModel 테스트·Demo용 공유 Mock — 결과는 `executeResult`로 주입한다.
/// `executeDelay`는 Demo의 "느린 네트워크" 시나리오 재현용.
/// (실행을 멈춰 세워야 하는 경합 시나리오는 각 테스트가 전용 fake를 따로 둔다.)
///
/// 상태는 NSLock으로 지킨다 — 주입·검증은 테스트 스레드에서, `execute()`는 VM의 자식 태스크에서
/// 일어나 실행 컨텍스트가 갈린다(레포 공용 Mock 패턴).
public final class MockBootstrapAppUseCase: BootstrapAppUseCase, @unchecked Sendable {

    private struct State {
        var executeResult: BootstrapOutcome = .main(needsTermsAgreement: false)
        var executeDelay: Duration = .zero
        var executeCallCount = 0
    }

    private let lock = NSLock()
    private var state = State()

    public var executeResult: BootstrapOutcome {
        get { lock.withLock { state.executeResult } }
        set { lock.withLock { state.executeResult = newValue } }
    }

    public var executeDelay: Duration {
        get { lock.withLock { state.executeDelay } }
        set { lock.withLock { state.executeDelay = newValue } }
    }

    public var executeCallCount: Int { lock.withLock { state.executeCallCount } }

    public init() {}

    public func execute() async -> BootstrapOutcome {
        // 카운터 증가와 주입값 읽기를 한 번의 락 안에서 끝내고, 대기는 락 밖에서 한다.
        let (result, delay) = lock.withLock {
            state.executeCallCount += 1
            return (state.executeResult, state.executeDelay)
        }

        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        return result
    }
}
