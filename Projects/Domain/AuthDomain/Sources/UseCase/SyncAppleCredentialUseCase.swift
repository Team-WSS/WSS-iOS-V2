//
//  SyncAppleCredentialUseCase.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//



import Foundation

public protocol SyncAppleCredentialUseCase {
    func execute(
        credential: AppleSyncCredential
    ) async throws
}

public struct DefaultSyncAppleCredentialUseCase: SyncAppleCredentialUseCase {
    private let repository: AuthRepository

    public init(repository: AuthRepository) {
        self.repository = repository
    }

    public func execute(credential: AppleSyncCredential) async throws {
        try await repository.syncAppleCredential(credential)
    }
}
