//
//  DeleteNovelNotificationSubscriptionsUseCase.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol DeleteNovelNotificationSubscriptionsUseCase: Sendable {
    func execute(type: NovelNotificationType, novelIDs: [NovelID]) async throws(RepositoryError)
}

public final class DefaultDeleteNovelNotificationSubscriptionsUseCase: DeleteNovelNotificationSubscriptionsUseCase {
    private let repository: NovelNotificationRepository

    public init(repository: NovelNotificationRepository) {
        self.repository = repository
    }

    public func execute(type: NovelNotificationType, novelIDs: [NovelID]) async throws(RepositoryError) {
        try await repository.deleteSubscriptions(type: type, novelIDs: novelIDs)
    }
}
