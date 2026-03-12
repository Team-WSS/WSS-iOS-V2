//
//  UpdateProfileVisibilityUseCase.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

import BaseDomain

public protocol UpdateProfileVisibilityUseCase {
    func execute(_ visibility: ProfileVisibility) async throws(RepositoryError)
}

public final class DefaultUpdateProfileVisibilityUseCase: UpdateProfileVisibilityUseCase {
    private let repository: ProfileRepository

    public init(repository: ProfileRepository) {
        self.repository = repository
    }

    public func execute(_ visibility: ProfileVisibility) async throws(RepositoryError) {
        try await repository.updateProfileVisibility(visibility)
    }
}
