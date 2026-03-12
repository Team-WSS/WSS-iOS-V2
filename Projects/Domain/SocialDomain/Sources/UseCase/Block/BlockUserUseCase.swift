//
//  BlockUserUseCase.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol BlockUserUseCase {
    func execute(id: UserID) async throws(RepositoryError)
}

public final class DefaultBlockUserUseCase: BlockUserUseCase {
    private let repository: SocialRepository
    
    public init(repository: SocialRepository) {
        self.repository = repository
    }
    
    public func execute(id: UserID) async throws(RepositoryError) {
        try await repository.blockUser(id: id)
    }
}
