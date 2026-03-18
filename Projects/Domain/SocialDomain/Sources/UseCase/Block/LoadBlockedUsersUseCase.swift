//
//  BlockUserUseCase.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadBlockedUsersUseCase {
    func execute() async throws(RepositoryError) -> [BlockedUser]
}

public final class DefaultLoadBlockedUsersUseCase: LoadBlockedUsersUseCase {
    private let repository: SocialRepository
    
    public init(repository: SocialRepository) {
        self.repository = repository
    }
    
    public func execute() async throws(RepositoryError) -> [BlockedUser] {
        try await repository.loadBlockedUsers()
    }
}
