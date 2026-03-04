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

public final class MockCommentRepository: CommentRepository {

    public var fetchedFeedIDs: [FeedID] = []
    public var submittedComments: [(feedID: FeedID, draft: CommentDraft)] = []
    public var editedComments: [(id: CommentID, feedID: FeedID, draft: CommentDraft)] = []
    public var deletedComments: [(id: CommentID, feedID: FeedID)] = []

    public var fetchCommentsResult: Result<[FeedComment], Error> = .success([])
    public var submitResult: Result<Void, Error> = .success(())
    public var editResult: Result<Void, Error> = .success(())
    public var deleteResult: Result<Void, Error> = .success(())

    public init() {}

    public func fetchComments(feedID: FeedID) async throws -> [FeedComment] {
        fetchedFeedIDs.append(feedID)
        switch fetchCommentsResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    public func submitComment(feedID: FeedID, draft: CommentDraft) async throws {
        submittedComments.append((feedID, draft))
        switch submitResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    public func editComment(id: CommentID, feedID: FeedID, draft: CommentDraft) async throws {
        editedComments.append((id, feedID, draft))
        switch editResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    public func deleteComment(id: CommentID, feedID: FeedID) async throws {
        deletedComments.append((id, feedID))
        switch deleteResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
