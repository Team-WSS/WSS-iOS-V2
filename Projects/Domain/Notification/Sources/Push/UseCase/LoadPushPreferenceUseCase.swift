//
//  LoadPushPreferenceUseCase.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol LoadPushPreferenceUseCase: Sendable {
    func execute() async throws(RepositoryError) -> PushPreference
}

public final class DefaultLoadPushPreferenceUseCase: LoadPushPreferenceUseCase {
    private let repository: PushSettingRepository

    public init(repository: PushSettingRepository) {
        self.repository = repository
    }

    public func execute() async throws(RepositoryError) -> PushPreference {
        try await repository.loadPushPreference()
    }
}
