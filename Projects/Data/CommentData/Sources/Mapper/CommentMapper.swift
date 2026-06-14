//
//  CommentMapper.swift
//  CommentData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import CommentDomain
import BaseDomain

enum CommentMapper {
    static func comments(from dto: CommentsResponse) -> [FeedComment] {
        return dto.comments.map { comment(from: $0) }
    }
    
    static func comment(from dto: CommentResponse) -> FeedComment {
        let profileImageURL = URL(string: dto.avatarImage)
        let commentAuthor = Author(
            userId: UserID(dto.userId),
            nickname: dto.nickname,
            profileImage: profileImageURL
        )
        
        return FeedComment(
            id: CommentID(dto.commentId),
            user: commentAuthor,
            createdDate: dto.createdDate,
            content: dto.commentContent,
            isModified: dto.isModified,
            isSpoiler: dto.isSpoiler,
            isBlocked: dto.isBlocked,
            isHidden: dto.isHidden
        )
    }
    
    static func commentDraft(from draft: CommentDraft) -> CommentRequest {
        return CommentRequest(
            commentContent: draft.content
        )
    }
}
