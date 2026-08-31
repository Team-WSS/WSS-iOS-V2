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
public final class MockBootstrapAppUseCase: BootstrapAppUseCase, @unchecked Sendable {

    public var executeResult: BootstrapOutcome = .main(needsTermsAgreement: false)
    public var executeDelay: Duration = .zero

    public private(set) var executeCallCount = 0

    public init() {}

    public func execute() async -> BootstrapOutcome {
        executeCallCount += 1
        if executeDelay > .zero {
            try? await Task.sleep(for: executeDelay)
        }
        return executeResult
    }
}
