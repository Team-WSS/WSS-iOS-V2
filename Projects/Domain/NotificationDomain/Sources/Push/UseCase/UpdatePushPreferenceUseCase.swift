//
//  UpdatePushPreferenceUseCase.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol UpdatePushPreferenceUseCase: Sendable {
    func execute(pushPreference: PushPreference) async throws(RepositoryError)
}

public final class DefaultUpdatePushPreferenceUseCase: UpdatePushPreferenceUseCase {
    private let repository: PushSettingRepository

    public init(repository: PushSettingRepository) {
        self.repository = repository
    }

    public func execute(pushPreference: PushPreference) async throws(RepositoryError) {
        try await repository.updatePushPreference(pushPreference)
    }
}
