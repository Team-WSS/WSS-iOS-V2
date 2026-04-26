//
//  CommentService.swift
//  CommentData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

protocol CommentService {
    func fetchComments(feedId: Int) async throws -> CommentsResponse
    func postComment(feedId: Int, _ request: CommentRequest) async throws
    func putComment(feedId: Int, commentId: Int, _ request: CommentRequest) async throws
    func deleteComment(feedId: Int, commentId: Int) async throws
}
