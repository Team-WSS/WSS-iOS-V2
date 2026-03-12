//
//  LoadInitialProfileUseCase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadInitialProfileUseCase {
    func execute() async throws(RepositoryError) -> ProfileDraft
}

public final class DefaultLoadProfileDraftUseCase: LoadInitialProfileUseCase {

    private let profileRepository: ProfileRepository

    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }

    public func execute() async throws(RepositoryError) -> ProfileDraft {
        try await profileRepository.loadInitialProfile()
    }
}
