//
//  UpdateProfileUseCase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol UpdateProfileUseCase {
    func execute(_ draft: ProfileDraft) async throws
}

public final class DefaultUpdateProfileUseCase: UpdateProfileUseCase {

    private let profileRepository: ProfileRepository

    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }

    public func execute(_ draft: ProfileDraft) async throws {
        try await profileRepository.updateProfile(draft)
    }
}
