//
//  DeleteCommentUsecase.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol DeleteCommentUsecase {
    func execute(commentID: CommentID, feedID: FeedID) async throws
}

public final class DefaultDeleteCommentUsecase: DeleteCommentUsecase {
    
    private let commentRepository: CommentRepository
    
    public init(repository: CommentRepository) {
        self.commentRepository = repository
    }
    
    public func execute(commentID: CommentID, feedID: FeedID) async throws {
        try await commentRepository.deleteComment(id: commentID, feedID: feedID)
    }
}
