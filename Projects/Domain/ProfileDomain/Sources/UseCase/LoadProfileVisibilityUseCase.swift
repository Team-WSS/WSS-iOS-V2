//
//  LoadProfileVisibilityUseCase.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadProfileVisibilityUseCase {
    func execute() async throws(RepositoryError) -> ProfileVisibility
}

public final class DefaultLoadProfileVisibilityUseCase: LoadProfileVisibilityUseCase {
    private let repository: ProfileRepository

    public init(repository: ProfileRepository) {
        self.repository = repository
    }

    public func execute() async throws(RepositoryError) -> ProfileVisibility {
        try await repository.loadProfileVisibility()
    }
}
