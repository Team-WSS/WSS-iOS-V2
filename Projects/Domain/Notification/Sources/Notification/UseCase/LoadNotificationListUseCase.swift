//
//  LoadNotificationListUseCase.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol LoadNotificationListUseCase: Sendable {
    func execute(lastNotificationID: NotificationID?, size: Int) async throws(RepositoryError) -> PagedNotifications
}

public final class DefaultLoadNotificationListUseCase: LoadNotificationListUseCase {
    private let repository: NotificationRepository
    private static let defaultSize = 20
    
    public init(repository: NotificationRepository) {
        self.repository = repository
    }

    public func execute(lastNotificationID: NotificationID?, size: Int = 20) async throws(RepositoryError) -> PagedNotifications {
        let size = size > 0 ? size : Self.defaultSize
        return try await repository.loadNotifications(lastNotificationID: lastNotificationID, size: size)
    }
}
