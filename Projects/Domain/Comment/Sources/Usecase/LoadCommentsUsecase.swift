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
    
    private let commentRepository: CommentRepository
    
    public init(repository: CommentRepository) {
        self.commentRepository = repository
    }
    
    public func execute(feedID: FeedID) async throws -> [FeedComment] {
        try await commentRepository.fetchComments(feedID: feedID)
    }
}
