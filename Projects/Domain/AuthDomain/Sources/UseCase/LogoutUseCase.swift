//
//  LogoutUseCase.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LogoutUseCase {
    func execute() async throws(RepositoryError)
}

public final class DefaultLogoutUseCase: LogoutUseCase {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func execute() async throws(RepositoryError) {
        try await authRepository.logout()
    }
}
