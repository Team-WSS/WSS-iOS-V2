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
    ) async throws(AuthError) -> NeedOnboarding
}

public final class DefaultSocialLoginUseCase: SocialLoginUseCase {

    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func execute(
        credential: SocialLoginCredential
    ) async throws(AuthError) -> NeedOnboarding {
        return try await authRepository.login(with: credential)
    }
}
