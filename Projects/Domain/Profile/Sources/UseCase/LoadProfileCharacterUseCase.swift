//
//  LoadProfileCharacterUseCase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadProfileCharacterUseCase {
    func execute() async throws(RepositoryError) -> [ProfileCharacter]
}

public final class DefaultLoadProfileCharacterUseCase: LoadProfileCharacterUseCase {
    
    private let profileRepository: ProfileRepository
    
    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    public func execute() async throws(RepositoryError) -> [ProfileCharacter] {
        try await profileRepository.fetchProfileCharacters()
    }
}
