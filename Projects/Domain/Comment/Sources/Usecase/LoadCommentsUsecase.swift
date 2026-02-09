//
//  FetchCommentsUsecase.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol LoadCommentsUsecase {
    func execute(feedID: FeedID) async throws -> [FeedComment]
}

public final class DefaultFetchCommentsUsecase: LoadCommentsUsecase {
    
    private let repository: CommentRepositoryProtocol
    
    public init(repository: CommentRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(feedID: FeedID) async throws -> [FeedComment] {
        try await repository.fetchComments(feedID: feedID)
    }
}
