//
//  LoadProfileCharacterUsecase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadProfileCharacterUsecase {
    func execute() async throws -> [ProfileCharacter]
}

public final class DefaultLoadProfileCharacterUsecase: LoadProfileCharacterUsecase {
    
    private let profileRepository: ProfileRepository
    
    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    public func execute() async throws -> [ProfileCharacter] {
        try await profileRepository.fetchProfileCharacters()
    }
}
