//
//  UnblockUserUseCase.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol UnblockUserUseCase {
    func execute(id: BlockID) async throws(RepositoryError)
}

public final class DefaultUnblockUserUseCase: UnblockUserUseCase {
    private let repository: SocialRepository
    
    public init(repository: SocialRepository) {
        self.repository = repository
    }
    
    public func execute(id: BlockID) async throws(RepositoryError) {
        try await repository.unblockUser(id: id)
    }
}
