//
//  LoadInitialProfileUseCase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadInitialProfileUseCase {
    func execute() async throws -> ProfileDraft
}

public final class DefaultLoadProfileDraftUseCase: LoadInitialProfileUseCase {

    private let profileRepository: ProfileRepository

    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }

    public func execute() async throws -> ProfileDraft {
        try await profileRepository.loadInitialProfile()
    }
}
