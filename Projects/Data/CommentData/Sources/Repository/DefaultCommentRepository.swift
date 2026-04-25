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
import Networking
import BaseData

public struct DefaultCommentRepository: CommentRepository {
    private let service: CommentService
    private let logger: DataLogger?
    
    init(
        service: CommentService,
         logger: DataLogger?
    ) {
        self.service = service
        self.logger = logger
    }
    
    public func fetchComments(feedID: FeedID) async throws(RepositoryError) -> (Int, [FeedComment]) {
        let action = CommentAction.fetchComments
        
        do {
            let response = try await service.fetchComments(feedId: feedID.value)
            let result = CommentMapper.comments(from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
    
    public func submitComment(feedID: FeedID,
                              draft: CommentDraft) async throws(RepositoryError) {
        let action = CommentAction.postComment
        
        do {
            let request = CommentMapper.commentDraft(from: draft)
            try await service.postComment(feedId: feedID.value, request)
            logger?.logSuccess(action: action.name)
        }  catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
    
    public func editComment(id: CommentID,
                            feedID: FeedID,
                            draft: CommentDraft) async throws(RepositoryError) {
        let action = CommentAction.patchComment
        
        do {
            let request = CommentMapper.commentDraft(from: draft)
            try await service.putComment(feedId: feedID.value, commentId: id.value, request)
            logger?.logSuccess(action: action.name)
        }  catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
    
    public func deleteComment(id: CommentID,
                              feedID: FeedID) async throws(RepositoryError) {
        let action = CommentAction.deleteComment
        
        do {
            try await service.deleteComment(feedId: feedID.value, commentId: id.value)
            logger?.logSuccess(action: action.name)
        }  catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
}
