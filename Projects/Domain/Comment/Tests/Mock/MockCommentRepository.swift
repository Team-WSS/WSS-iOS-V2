//
//  MockCommentRepository.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import CommentDomain
import BaseDomain

final class MockCommentRepository: CommentRepository {

    var fetchedFeedIDs: [FeedID] = []
    var submittedComments: [(feedID: FeedID, draft: CommentDraft)] = []
    var editedComments: [(id: CommentID, feedID: FeedID, draft: CommentDraft)] = []
    var deletedComments: [(id: CommentID, feedID: FeedID)] = []

    var fetchCommentsResult: Result<[FeedComment], Error> = .success([])
    var submitResult: Result<Void, Error> = .success(())
    var editResult: Result<Void, Error> = .success(())
    var deleteResult: Result<Void, Error> = .success(())
    
    var reportedSpoilerCommentID: CommentID?
    var reportSpoilerResult: Result<Void, Error> = .success(())
    var reportedImproperCommentID: CommentID?
    var reportImproperResult: Result<Void, Error> = .success(())

    func fetchComments(feedID: FeedID) async throws -> [FeedComment] {
        fetchedFeedIDs.append(feedID)
        switch fetchCommentsResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func submitComment(feedID: FeedID, draft: CommentDraft) async throws {
        submittedComments.append((feedID, draft))
        switch submitResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func editComment(id: CommentID, feedID: FeedID, draft: CommentDraft) async throws {
        editedComments.append((id, feedID, draft))
        switch editResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func deleteComment(id: CommentID, feedID: FeedID) async throws {
        deletedComments.append((id, feedID))
        switch deleteResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Report
    
    func reportSpoilerComment(id: CommentID) async throws {
        reportedSpoilerCommentID = id
        
        switch reportSpoilerResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func reportImproperComment(id: CommentID) async throws {
        reportedImproperCommentID = id
        
        switch reportImproperResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
