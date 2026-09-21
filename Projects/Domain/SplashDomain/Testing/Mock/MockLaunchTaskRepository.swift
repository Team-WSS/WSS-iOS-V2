//
//  MockLaunchTaskRepository.swift
//  SplashDomainTesting
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import SplashDomain

/// 부수 태스크 4종은 UseCase가 `async let`으로 **동시에** 부른다 — 카운터를 NSLock으로 지킨다.
public final class MockLaunchTaskRepository: LaunchTaskRepository, @unchecked Sendable {

    private struct State {
        var syncUserBasicInfoResult: Result<Void, RepositoryError> = .success(())
        var registerDeviceTokenIfNeededResult: Result<Void, RepositoryError> = .success(())

        var syncUserBasicInfoCallCount = 0
        var registerDeviceTokenIfNeededCallCount = 0
        var syncKeywordsCallCount = 0
        var prefetchHomeDataCallCount = 0
    }

    private let lock = NSLock()
    private var state = State()

    // MARK: - 주입할 결과 (기본값 = 전부 성공)

    public var syncUserBasicInfoResult: Result<Void, RepositoryError> {
        get { lock.withLock { state.syncUserBasicInfoResult } }
        set { lock.withLock { state.syncUserBasicInfoResult = newValue } }
    }

    public var registerDeviceTokenIfNeededResult: Result<Void, RepositoryError> {
        get { lock.withLock { state.registerDeviceTokenIfNeededResult } }
        set { lock.withLock { state.registerDeviceTokenIfNeededResult = newValue } }
    }

    // MARK: - 호출 기록

    public var syncUserBasicInfoCallCount: Int { lock.withLock { state.syncUserBasicInfoCallCount } }
    public var registerDeviceTokenIfNeededCallCount: Int { lock.withLock { state.registerDeviceTokenIfNeededCallCount } }
    public var syncKeywordsCallCount: Int { lock.withLock { state.syncKeywordsCallCount } }
    public var prefetchHomeDataCallCount: Int { lock.withLock { state.prefetchHomeDataCallCount } }

    public init() {}

    public func syncUserBasicInfo() async throws(RepositoryError) {
        let result = lock.withLock {
            state.syncUserBasicInfoCallCount += 1
            return state.syncUserBasicInfoResult
        }
        try result.get()
    }

    public func registerDeviceTokenIfNeeded() async throws(RepositoryError) {
        let result = lock.withLock {
            state.registerDeviceTokenIfNeededCallCount += 1
            return state.registerDeviceTokenIfNeededResult
        }
        try result.get()
    }

    public func syncKeywords() async {
        lock.withLock { state.syncKeywordsCallCount += 1 }
    }

    public func prefetchHomeData() async {
        lock.withLock { state.prefetchHomeDataCallCount += 1 }
    }
}
