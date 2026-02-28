//
//  LogoutUseCase.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

public protocol LogoutUseCase {
    func execute() async throws
}

public final class DefaultLogoutUseCase: LogoutUseCase {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func execute() async throws {
        try await authRepository.logout()
    }
}
