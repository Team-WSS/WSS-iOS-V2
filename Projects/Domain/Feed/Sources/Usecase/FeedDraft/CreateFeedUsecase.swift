//
//  CreateFeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol CreateFeedUsecase {
    func execute(_ draft: FeedDraft) async throws
}

public final class DefaultCreateFeedUseCase: CreateFeedUsecase {

    private let repository: FeedRepository

    public init(repository: FeedRepository) {
        self.repository = repository
    }

    public func execute(_ draft: FeedDraft) async throws {
        try await repository.submitFeed(draft)
    }
}
