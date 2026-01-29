//
//  FeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct FeedUsecase: FeedUsecaseProtocol {
    
    private let repository: FeedRepositoryProtocol
    
    public init(repository: FeedRepositoryProtocol) {
        self.repository = repository
    }
    
    public func createFeed(draft: FeedDraftEntity) async throws {
        switch draft.submissionValidationResult {
        case .valid:
            try await repository.submitFeed(draft)
        case .invalid(let reason):
            throw CreateFeedError.invalidDraft(reason: reason)
        }
    }
}
