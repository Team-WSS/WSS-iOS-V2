//
//  LoadInitialProfileUsecase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadInitialProfileUsecase {
    func execute() async throws -> ProfileDraft
}

public final class DefaultLoadProfileDraftUsecase: LoadInitialProfileUsecase {

    private let profileRepository: ProfileRepository

    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }

    public func execute() async throws -> ProfileDraft {
        try await profileRepository.loadInitialProfile()
    }
}
