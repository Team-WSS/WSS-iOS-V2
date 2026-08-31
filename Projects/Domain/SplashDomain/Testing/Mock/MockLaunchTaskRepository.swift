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

public final class MockLaunchTaskRepository: LaunchTaskRepository, @unchecked Sendable {

    // MARK: - 주입할 결과 (기본값 = 전부 성공)

    public var syncUserBasicInfoResult: Result<Void, RepositoryError> = .success(())
    public var registerDeviceTokenIfNeededResult: Result<Void, RepositoryError> = .success(())

    // MARK: - 호출 기록

    public private(set) var syncUserBasicInfoCallCount = 0
    public private(set) var registerDeviceTokenIfNeededCallCount = 0
    public private(set) var syncKeywordsCallCount = 0
    public private(set) var prefetchHomeDataCallCount = 0

    public init() {}

    public func syncUserBasicInfo() async throws(RepositoryError) {
        syncUserBasicInfoCallCount += 1
        try syncUserBasicInfoResult.get()
    }

    public func registerDeviceTokenIfNeeded() async throws(RepositoryError) {
        registerDeviceTokenIfNeededCallCount += 1
        try registerDeviceTokenIfNeededResult.get()
    }

    public func syncKeywords() async {
        syncKeywordsCallCount += 1
    }

    public func prefetchHomeData() async {
        prefetchHomeDataCallCount += 1
    }
}
