//
//  FetchCommentsUsecase.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol FetchCommentsUsecase {
    func execute(feedID: FeedID) async throws -> [Comment]
}

public final class DefaultFetchCommentsUsecase: FetchCommentsUsecase {
    
    private let repository: CommentRepositoryProtocol
    
    init(repository: CommentRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(feedID: FeedID) async throws -> [Comment] {
        try await repository.fetchComments(feedID: feedID)
    }
}
