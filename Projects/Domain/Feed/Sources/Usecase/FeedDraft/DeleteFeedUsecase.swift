//
//  DeleteFeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol DeleteFeedUsecase {
    func execute(feedID: FeedID) async throws
}

public final class DefaultDeleteFeedUseCase: DeleteFeedUsecase {

    private let repository: FeedRepositoryProtocol

    public init(repository: FeedRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(feedID: FeedID) async throws {
        try await repository.deleteFeed(id: feedID)
    }
}
