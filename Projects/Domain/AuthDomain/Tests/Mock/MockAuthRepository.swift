//
//  MockAuthRepository.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import AuthDomain

final class MockAuthRepository: AuthRepository {
    
    // login
    var loginResult: Result<AuthSession, AuthError> = .failure(.unknown)
    private(set) var loginCallCount: Int = 0
    private(set) var loginReceivedCredential: SocialLoginCredential?

    func login(with credential: SocialLoginCredential) async throws(AuthError) -> AuthSession {
        loginCallCount += 1
        loginReceivedCredential = credential
        return try loginResult.get()
    }
    
    // logout
    var logoutResult: Result<Void, RepositoryError> = .success(())
    private(set) var logoutCallCount: Int = 0

    func logout() async throws(RepositoryError) {
        logoutCallCount += 1
        _ = try logoutResult.get()
    }
    
    // withdraw
    var withdrawResult: Result<Void, RepositoryError> = .success(())
    private(set) var withdrawCallCount: Int = 0
    private(set) var withdrawReceivedDraft: WithdrawalReasonDraft?

    func withdraw(draft: WithdrawalReasonDraft) async throws(RepositoryError) {
        withdrawCallCount += 1
        withdrawReceivedDraft = draft
        _ = try withdrawResult.get()
    }
    
    // syncAppleCredential
    var syncResult: Result<Void, AuthError> = .success(())
    private(set) var syncCallCount: Int = 0
    private(set) var syncReceivedCredential: AppleSyncCredential?

    func syncAppleCredential(_ credential: AppleSyncCredential) async throws(AuthError) {
        syncCallCount += 1
        syncReceivedCredential = credential
        _ = try syncResult.get()
    }
}
