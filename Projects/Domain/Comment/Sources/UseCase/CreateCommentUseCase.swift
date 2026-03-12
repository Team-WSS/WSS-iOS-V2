//
//  CreateCommentUseCase.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol CreateCommentUseCase {
    func execute(feedID: FeedID, _ draft: CommentDraft) async throws(RepositoryError)
}

public final class DefaultCreateCommentUseCase: CreateCommentUseCase {
    
    private let commentRepository: CommentRepository
    
    public init(repository: CommentRepository) {
        self.commentRepository = repository
    }
    
    public func execute(feedID: FeedID, _ draft: CommentDraft) async throws(RepositoryError) {
        try await commentRepository.submitComment(feedID: feedID, draft: draft)
    }
}
