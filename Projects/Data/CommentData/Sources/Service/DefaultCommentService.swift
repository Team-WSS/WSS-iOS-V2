//
//  DefaultCommentService.swift
//  CommentData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

public struct DefaultCommentService: CommentService {
    
    private let client: NetworkingRequestable

    public init(client: NetworkingRequestable) {
        self.client = client
    }
    
    func fetchComments(feedId: Int) async throws -> CommentsResponse {
        let endpoint = CommentEndpoint.getComments(feedId: feedId)
        return try await client.request(endpoint,
                                        decodeTo: CommentsResponse.self)
    }
    
    func postComment(feedId: Int, _ request: CommentRequest) async throws {
        let endpoint = CommentEndpoint.postComment(feedId: feedId, request)
        _ = try await client.request(endpoint)
    }
    
    func putComment(feedId: Int, commentId: Int, _ request: CommentRequest) async throws {
        let endpoint = CommentEndpoint.putComment(feedId: feedId, commentId: commentId, request)
        _ = try await client.request(endpoint)
    }
    
    func deleteComment(feedId: Int, commentId: Int) async throws {
        let endpoint = CommentEndpoint.deleteComment(feedId: feedId, commentId: commentId)
        _ = try await client.request(endpoint)
    }
}
