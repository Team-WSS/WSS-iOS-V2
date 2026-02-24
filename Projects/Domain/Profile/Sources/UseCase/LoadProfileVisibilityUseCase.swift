//
//  LoadProfileVisibilityUseCase.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol LoadProfileVisibilityUseCase {
    func execute() async throws -> ProfileVisibility
}

public final class DefaultLoadProfileVisibilityUseCase: LoadProfileVisibilityUseCase {
    private let repository: ProfileRepository

    public init(repository: ProfileRepository) {
        self.repository = repository
    }

    public func execute() async throws -> ProfileVisibility {
        try await repository.loadProfileVisibility()
    }
}
