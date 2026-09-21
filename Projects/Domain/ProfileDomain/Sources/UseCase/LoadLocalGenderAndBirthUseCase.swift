//
//  LoadLocalGenderAndBirthUseCase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadLocalGenderAndBirthUseCase: Sendable {
    func execute() async throws(RepositoryError) -> AccountInfoDraft
}

public final class DefaultLoadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase {
    let repository: ProfileRepository

    public init(repository: ProfileRepository) {
        self.repository = repository
    }

    public func execute() async throws(RepositoryError) -> AccountInfoDraft {
        return try await repository.loadLocalGenderAndBirth()
    }
}
