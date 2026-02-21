//
//  SocialLoginUseCase.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol SocialLoginUseCase {
    func execute(
        credential: SocialLoginCredential
    ) async throws(AuthError) -> Bool
}

public final class DefaultSocialLoginUseCase: SocialLoginUseCase {

    private let authRepository: AuthRepository
    private let tokenStore: TokenStore

    public init(authRepository: AuthRepository, tokenStore: TokenStore) {
        self.authRepository = authRepository
        self.tokenStore = tokenStore
    }

    public func execute(
        credential: SocialLoginCredential
    ) async throws(AuthError) -> Bool {

        let session = try await authRepository.login(with: credential)
        tokenStore.save(session)
        return session.needOnboarding
    }
}
