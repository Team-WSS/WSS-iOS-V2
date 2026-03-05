//
//  LoadProfileCharacterUseCase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadProfileCharacterUseCase {
    func execute() async throws -> [ProfileCharacter]
}

public final class DefaultLoadProfileCharacterUseCase: LoadProfileCharacterUseCase {
    
    private let profileRepository: ProfileRepository
    
    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    public func execute() async throws -> [ProfileCharacter] {
        try await profileRepository.fetchProfileCharacters()
    }
}
