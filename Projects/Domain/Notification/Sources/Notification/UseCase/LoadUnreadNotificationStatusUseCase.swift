//
//  LoadUnreadNotificationStatusUseCase.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol LoadUnreadNotificationStatusUseCase: Sendable {
    func execute() async throws(RepositoryError) -> UnreadNotificationStatus
}

public final class DefaultLoadUnreadNotificationStatusUseCase: LoadUnreadNotificationStatusUseCase {
    private let repository: NotificationRepository

    public init(repository: NotificationRepository) {
        self.repository = repository
    }

    public func execute() async throws(RepositoryError) -> UnreadNotificationStatus {
        try await repository.loadUnreadNotificationStatus()
    }
}
