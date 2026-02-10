//
//  CheckForceUpdateUseCase.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol CheckForceUpdateRequirementUseCase {
    func execute() async throws -> Bool
}

public final class DefaultCheckForceUpdateRequirementUseCase: CheckForceUpdateRequirementUseCase {
    private let repository: AppUpdateRepository
    private let versionProvider: AppVersionProviding

    public init(repository: AppUpdateRepository, versionProvider: AppVersionProviding) {
        self.repository = repository
        self.versionProvider = versionProvider
    }

    public func execute() async throws -> Bool {
        let policy = try await repository.loadAppUpdatePolicy()
        return policy.requiresForceUpdate(current: versionProvider.currentVersion)
    }
}
