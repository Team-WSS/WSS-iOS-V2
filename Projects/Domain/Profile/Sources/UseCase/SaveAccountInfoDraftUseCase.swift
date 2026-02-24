//
//  SaveAccountInfoDraftUseCase.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol SaveAccountInfoDraftUseCase {
    func execute(_ info: AccountInfoDraft) async throws
}

public class DefaultSaveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase {
    let repository: ProfileRepository
    
    public init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    public func execute(_ info: AccountInfoDraft) async throws {
        return try await repository.saveAccountInfo(info)
    }
}
