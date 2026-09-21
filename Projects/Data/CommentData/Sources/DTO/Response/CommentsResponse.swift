//
//  CommentsResponse.swift
//  CommentData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct CommentsResponse: Decodable {
    let commentsCount: Int
    let comments: [CommentResponse]
}

struct CommentResponse: Decodable {
    let userId: Int
    let nickname: String
    let avatarImage: String
    let commentId: Int
    let createdDate: String
    let commentContent: String
    let isModified: Bool
    let isMyComment: Bool
    let isSpoiler: Bool
    let isBlocked: Bool
    let isHidden: Bool
}
