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

public final class MockLaunchGateRepository: LaunchGateRepository, @unchecked Sendable {

    // MARK: - 주입할 결과 (기본값 = 전 게이트 통과)

    public var hasValidSessionReturnValue = true
    public var checkForceUpdateRequiredResult: Result<Bool, RepositoryError> = .success(false)
    public var isRequiredTermsAgreedResult: Result<Bool, RepositoryError> = .success(true)

    // MARK: - 호출 기록

    public private(set) var hasValidSessionCallCount = 0
    public private(set) var checkForceUpdateRequiredCallCount = 0
    public private(set) var isRequiredTermsAgreedCallCount = 0

    public init() {}

    public func hasValidSession() -> Bool {
        hasValidSessionCallCount += 1
        return hasValidSessionReturnValue
    }

    public func checkForceUpdateRequired() async throws(RepositoryError) -> Bool {
        checkForceUpdateRequiredCallCount += 1
        return try checkForceUpdateRequiredResult.get()
    }

    public func isRequiredTermsAgreed() async throws(RepositoryError) -> Bool {
        isRequiredTermsAgreedCallCount += 1
        return try isRequiredTermsAgreedResult.get()
    }
}
