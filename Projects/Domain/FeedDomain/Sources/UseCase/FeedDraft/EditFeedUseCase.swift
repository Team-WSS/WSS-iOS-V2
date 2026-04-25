//
//  EditFeedUseCase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol EditFeedUseCase {
    func execute(feedID: FeedID, editedFeed: FeedDraft) async throws(RepositoryError)
}

public final class DefaultEditFeedUseCase: EditFeedUseCase {

    private let repository: FeedRepository

    public init(repository: FeedRepository) {
        self.repository = repository
    }

    public func execute(feedID: FeedID, editedFeed: FeedDraft) async throws(RepositoryError) {
        try await repository.editFeed(id: feedID, draft: editedFeed)
    }
}
