//
//  CommentRepository.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol CommentRepository {
    func fetchComments(feedID: FeedID) async throws(RepositoryError) -> (Int, [FeedComment])
    func submitComment(feedID: FeedID, draft: CommentDraft) async throws(RepositoryError)
    func editComment(id: CommentID, feedID: FeedID, draft: CommentDraft) async throws(RepositoryError)
    func deleteComment(id: CommentID, feedID: FeedID) async throws(RepositoryError)
}
