//
//  DefaultCommentRepository.swift
//  CommentData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import CommentDomain
import BaseDomain

public struct DefaultCommentRepository: CommentRepository {
    private let service: CommentService
    
    init(service: CommentService) {
        self.service = service
    }
    
    public func fetchComments(feedID: FeedID) async throws(RepositoryError) -> (Int, [FeedComment]) {
        do {
            let response = try await service.fetchComments(feedId: feedID.value)
            return CommentMapper.comments(from: response)
        } catch {

        }
    }
    
    public func submitComment(feedID: FeedID,
                              draft: CommentDraft) async throws(RepositoryError) {
        do {
            let request = CommentMapper.commentDraft(from: draft)
            try await service.postComment(feedId: feedID.value, request)
        } catch {
            
        }
    }
    
    public func editComment(id: CommentID,
                            feedID: FeedID,
                            draft: CommentDraft) async throws(RepositoryError) {
        do {
            let request = CommentMapper.commentDraft(from: draft)
            try await service.putComment(feedId: feedID.value, commentId: id.value, request)
        } catch {
            
        }
    }
    
    public func deleteComment(id: CommentID,
                              feedID: FeedID) async throws(RepositoryError) {
        do {
            try await service.deleteComment(feedId: feedID.value, commentId: id.value)
        } catch {
            
        }
    }
}
