//
//  UpdateNovelNotificationSettingUseCase.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol UpdateNovelNotificationSettingUseCase: Sendable {
    func execute(novelID: NovelID, setting: NovelNotificationSetting) async throws(RepositoryError)
}

public final class DefaultUpdateNovelNotificationSettingUseCase: UpdateNovelNotificationSettingUseCase {
    private let repository: NovelNotificationRepository

    public init(repository: NovelNotificationRepository) {
        self.repository = repository
    }

    public func execute(novelID: NovelID, setting: NovelNotificationSetting) async throws(RepositoryError) {
        try await repository.updateNotificationSetting(novelID: novelID, setting: setting)
    }
}
