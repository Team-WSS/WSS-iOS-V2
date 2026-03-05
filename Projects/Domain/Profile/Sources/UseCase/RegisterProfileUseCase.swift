//
//  RegisterProfileUseCase.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol RegisterProfileUseCase {
    func execute(_ profile: ProfileRegistration) async throws
}

public class DefaultRegisterProfileUseCase: RegisterProfileUseCase {
    let repository: ProfileRepository
    
    public init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    public func execute(_ profile: ProfileRegistration) async throws {
        _ = try await repository.registerProfile(profile)
    }
}
