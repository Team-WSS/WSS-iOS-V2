//
//  CreateFeedUseCase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol CreateFeedUseCase {
    func execute(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError)
}

public final class DefaultCreateFeedUseCase: CreateFeedUseCase {

    private let repository: FeedRepository

    public init(repository: FeedRepository) {
        self.repository = repository
    }

    public func execute(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError) {
        try await repository.submitFeed(draft, imageDatas: imageDatas)
    }
}
