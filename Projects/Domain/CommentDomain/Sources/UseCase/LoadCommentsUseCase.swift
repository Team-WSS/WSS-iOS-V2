//
//  FetchCommentsUseCase.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadCommentsUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) -> [FeedComment]
}

public final class DefaultLoadCommentsUseCase: LoadCommentsUseCase {
    
    private let commentRepository: CommentRepository
    
    public init(repository: CommentRepository) {
        self.commentRepository = repository
    }
    
    public func execute(feedID: FeedID) async throws(RepositoryError) -> [FeedComment] {
        try await commentRepository.fetchComments(feedID: feedID)
    }
}
