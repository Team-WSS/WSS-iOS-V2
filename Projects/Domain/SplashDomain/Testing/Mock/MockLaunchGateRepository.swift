//
//  MockLaunchGateRepository.swift
//  SplashDomainTesting
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import SplashDomain

/// 게이트 호출은 UseCase의 예산 task group 안에서 일어나고 검증은 테스트 스레드에서 하므로,
/// 실행 컨텍스트가 갈린다 — 카운터를 NSLock으로 지킨다.
public final class MockLaunchGateRepository: LaunchGateRepository, @unchecked Sendable {

    private struct State {
        var hasValidSessionReturnValue = true
        var checkForceUpdateRequiredResult: Result<Bool, RepositoryError> = .success(false)
        var isRequiredTermsAgreedResult: Result<Bool, RepositoryError> = .success(true)

        var hasValidSessionCallCount = 0
        var checkForceUpdateRequiredCallCount = 0
        var isRequiredTermsAgreedCallCount = 0
    }

    private let lock = NSLock()
    private var state = State()

    // MARK: - 주입할 결과 (기본값 = 전 게이트 통과)

    public var hasValidSessionReturnValue: Bool {
        get { lock.withLock { state.hasValidSessionReturnValue } }
        set { lock.withLock { state.hasValidSessionReturnValue = newValue } }
    }

    public var checkForceUpdateRequiredResult: Result<Bool, RepositoryError> {
        get { lock.withLock { state.checkForceUpdateRequiredResult } }
        set { lock.withLock { state.checkForceUpdateRequiredResult = newValue } }
    }

    public var isRequiredTermsAgreedResult: Result<Bool, RepositoryError> {
        get { lock.withLock { state.isRequiredTermsAgreedResult } }
        set { lock.withLock { state.isRequiredTermsAgreedResult = newValue } }
    }

    // MARK: - 호출 기록

    public var hasValidSessionCallCount: Int { lock.withLock { state.hasValidSessionCallCount } }
    public var checkForceUpdateRequiredCallCount: Int { lock.withLock { state.checkForceUpdateRequiredCallCount } }
    public var isRequiredTermsAgreedCallCount: Int { lock.withLock { state.isRequiredTermsAgreedCallCount } }

    public init() {}

    public func hasValidSession() -> Bool {
        lock.withLock {
            state.hasValidSessionCallCount += 1
            return state.hasValidSessionReturnValue
        }
    }

    public func checkForceUpdateRequired() async throws(RepositoryError) -> Bool {
        let result = lock.withLock {
            state.checkForceUpdateRequiredCallCount += 1
            return state.checkForceUpdateRequiredResult
        }
        return try result.get()
    }

    public func isRequiredTermsAgreed() async throws(RepositoryError) -> Bool {
        let result = lock.withLock {
            state.isRequiredTermsAgreedCallCount += 1
            return state.isRequiredTermsAgreedResult
        }
        return try result.get()
    }
}
