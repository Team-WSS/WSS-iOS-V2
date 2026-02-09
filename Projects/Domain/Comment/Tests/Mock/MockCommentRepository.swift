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

enum MockError: Error, Equatable {
    case networkUnavailable
    case notFound
}

final class MockCommentRepository: CommentRepositoryProtocol {

    var fetchedFeedIDs: [FeedID] = []
    var submittedComments: [(feedID: FeedID, draft: CommentDraft)] = []
    var editedComments: [(id: CommentID, feedID: FeedID, draft: CommentDraft)] = []
    var deletedComments: [(id: CommentID, feedID: FeedID)] = []

    var fetchCommentsResult: Result<[FeedComment], Error> = .success([])
    var submitResult: Result<Void, Error> = .success(())
    var editResult: Result<Void, Error> = .success(())
    var deleteResult: Result<Void, Error> = .success(())

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
}
