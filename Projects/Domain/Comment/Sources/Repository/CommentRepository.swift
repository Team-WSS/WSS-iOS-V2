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
    func fetchComments(feedID: FeedID) async throws -> [FeedComment]
    
    func submitComment(feedID: FeedID, draft: CommentDraft) async throws
    func editComment(id: CommentID, feedID: FeedID, draft: CommentDraft) async throws
    func deleteComment(id: CommentID, feedID: FeedID) async throws
    
    func reportSpoilerComment(id: CommentID) async throws
    func reportImproperComment(id: CommentID) async throws
}
