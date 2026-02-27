//
//  UpdateProfileUsecase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol UpdateProfileUsecase {
    func execute(_ draft: ProfileDraft) async throws
}

public final class DefaultUpdateProfileUsecase: UpdateProfileUsecase {

    private let profileRepository: ProfileRepository

    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }

    public func execute(_ draft: ProfileDraft) async throws {
        try await profileRepository.updateProfile(draft)
    }
}
