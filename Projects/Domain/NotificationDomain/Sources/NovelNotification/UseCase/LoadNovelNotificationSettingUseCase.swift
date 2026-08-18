//
//  LoadNovelNotificationSettingUseCase.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol LoadNovelNotificationSettingUseCase: Sendable {
    func execute(novelID: NovelID) async throws(RepositoryError) -> NovelNotificationSetting
}

public final class DefaultLoadNovelNotificationSettingUseCase: LoadNovelNotificationSettingUseCase {
    private let repository: NovelNotificationRepository

    public init(repository: NovelNotificationRepository) {
        self.repository = repository
    }

    public func execute(novelID: NovelID) async throws(RepositoryError) -> NovelNotificationSetting {
        try await repository.loadNotificationSetting(novelID: novelID)
    }
}
