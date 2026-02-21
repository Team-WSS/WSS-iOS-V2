//
//  MarkNotificationAsReadUseCase.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  MarkNotificationAsReadUseCase.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol MarkNotificationAsReadUseCase: Sendable {
    func execute(id: NotificationID) async throws(RepositoryError)
}

public final class DefaultMarkNotificationAsReadUseCase: MarkNotificationAsReadUseCase {
    private let repository: NotificationRepository

    public init(repository: NotificationRepository) {
        self.repository = repository
    }

    public func execute(id: NotificationID) async throws(RepositoryError) {
        try await repository.markAsRead(id: id)
    }
}