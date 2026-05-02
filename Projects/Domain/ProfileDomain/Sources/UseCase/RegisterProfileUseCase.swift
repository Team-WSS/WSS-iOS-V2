//
//  RegisterProfileUseCase.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol RegisterProfileUseCase {
    func execute(_ profile: ProfileRegistration) async throws(RepositoryError)
}

public class DefaultRegisterProfileUseCase: RegisterProfileUseCase {
    let repository: ProfileRepository
    
    public init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    public func execute(_ profile: ProfileRegistration) async throws(RepositoryError) {
        _ = try await repository.registerProfile(profile)
    }
}
