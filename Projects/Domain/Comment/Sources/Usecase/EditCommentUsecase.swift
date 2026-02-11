//
//  EditCommentUsecase.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol EditCommentUsecase {
    func execute(commentID: CommentID, feedID: FeedID, _ draft: CommentDraft) async throws
}

public final class DefaultEditCommentUsecase: EditCommentUsecase {
    
    private let commentRepository: CommentRepository
    
    public init(repository: CommentRepository) {
        self.commentRepository = repository
    }
    
    public func execute(commentID: CommentID, feedID: FeedID, _ draft: CommentDraft) async throws {
        try await commentRepository.editComment(id: commentID, feedID: feedID, draft: draft)
    }
}
