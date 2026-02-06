//
//  EditFeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol EditFeedUsecase {
    func execute(feedID: FeedID, editedFeed: FeedDraft) async throws
}

public final class DefaultEditFeedUseCase: EditFeedUsecase {

    private let repository: FeedRepositoryProtocol

    public init(repository: FeedRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(feedID: FeedID, editedFeed: FeedDraft) async throws {
        try await repository.editFeed(id: feedID, draft: editedFeed)
    }
}
