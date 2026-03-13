//
//  MockAuthRepository.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import AuthDomain
import BaseDomain

public final class MockAuthRepository: AuthRepository {
    
    public init() {}
    
    // login
    public var loginResult: Result<NeedOnboarding, AuthError> = .failure(.unknown)
    public private(set) var loginCallCount: Int = 0
    public private(set) var loginReceivedCredential: SocialLoginCredential?

    public func login(with credential: SocialLoginCredential) async throws(AuthError) -> NeedOnboarding {
        loginCallCount += 1
        loginReceivedCredential = credential
        return try loginResult.get()
    }
    
    // logout
    public var logoutResult: Result<Void, RepositoryError> = .success(())
    public private(set) var logoutCallCount: Int = 0

    public func logout() async throws(RepositoryError) {
        logoutCallCount += 1
        _ = try logoutResult.get()
    }
    
    // withdraw
    public var withdrawResult: Result<Void, RepositoryError> = .success(())
    public private(set) var withdrawCallCount: Int = 0
    public private(set) var withdrawReceivedDraft: WithdrawalReasonDraft?

    public func withdraw(draft: WithdrawalReasonDraft) async throws(RepositoryError) {
        withdrawCallCount += 1
        withdrawReceivedDraft = draft
        _ = try withdrawResult.get()
    }
    
    // syncAppleCredential
    public var syncResult: Result<Void, AuthError> = .success(())
    public private(set) var syncCallCount: Int = 0
    public private(set) var syncReceivedCredential: AppleSyncCredential?

    public func syncAppleCredential(_ credential: AppleSyncCredential) async throws(AuthError) {
        syncCallCount += 1
        syncReceivedCredential = credential
        _ = try syncResult.get()
    }
}
