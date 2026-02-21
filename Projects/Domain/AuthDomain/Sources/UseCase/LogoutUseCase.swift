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
    private let tokenStore: TokenStore
    private let userDataStore: UserDataStore

    public init(
        authRepository: AuthRepository,
        tokenStore: TokenStore,
        userDataStore: UserDataStore
    ) {
        self.authRepository = authRepository
        self.tokenStore = tokenStore
        self.userDataStore = userDataStore
    }

    public func execute() async throws {
        try await authRepository.logout()
        tokenStore.clear()
        userDataStore.clearUserData()
    }
}
