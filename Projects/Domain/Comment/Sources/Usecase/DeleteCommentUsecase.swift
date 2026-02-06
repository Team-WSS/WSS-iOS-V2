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
    
    private let repository: CommentRepositoryProtocol
    
    public init(repository: CommentRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(commentID: CommentID, feedID: FeedID) async throws {
        try await repository.deleteComment(id: commentID, feedID: feedID)
    }
}
