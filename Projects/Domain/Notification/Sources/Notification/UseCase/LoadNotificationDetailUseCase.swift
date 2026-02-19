//
//  LoadNotificationDetailUseCase.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol LoadNotificationDetailUseCase: Sendable {
    func execute(id: NotificationID) async throws(RepositoryError) -> NotificationDetail
}

public final class DefaultLoadNotificationDetailUseCase: LoadNotificationDetailUseCase {
    private let repository: NotificationRepository

    public init(repository: NotificationRepository) {
        self.repository = repository
    }

    public func execute(id: NotificationID) async throws(RepositoryError) -> NotificationDetail {
        try await repository.loadNotificationDetail(id: id)
    }
}
