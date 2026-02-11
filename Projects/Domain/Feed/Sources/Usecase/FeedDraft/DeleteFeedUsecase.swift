//
//  DeleteFeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol DeleteFeedUsecase {
    func execute(feedID: FeedID) async throws
}

public final class DefaultDeleteFeedUseCase: DeleteFeedUsecase {

    private let repository: FeedRepository

    public init(repository: FeedRepository) {
        self.repository = repository
    }

    public func execute(feedID: FeedID) async throws {
        try await repository.deleteFeed(id: feedID)
    }
}
