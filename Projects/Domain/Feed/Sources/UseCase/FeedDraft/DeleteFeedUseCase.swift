//
//  DeleteFeedUseCase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol DeleteFeedUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError)
}

public final class DefaultDeleteFeedUseCase: DeleteFeedUseCase {

    private let repository: FeedRepository

    public init(repository: FeedRepository) {
        self.repository = repository
    }

    public func execute(feedID: FeedID) async throws(RepositoryError) {
        try await repository.deleteFeed(id: feedID)
    }
}
