//
//  FeedComment.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct FeedComment: Sendable {
    
    public let id: CommentID
    
    public let user: Author
    public let createdDate: String
    public let content: String
    
    public let isModified: Bool

    public let isSpoiler: Bool
    public let isBlocked: Bool
    public let isHidden: Bool
    
    public init(
        id: CommentID,
        user: Author,
        createdDate: String,
        content: String,
        isModified: Bool,
        isSpoiler: Bool,
        isBlocked: Bool,
        isHidden: Bool
    ) {
        self.id = id
        self.user = user
        self.createdDate = createdDate
        self.content = content
        self.isModified = isModified
        self.isSpoiler = isSpoiler
        self.isBlocked = isBlocked
        self.isHidden = isHidden
    }

    // MARK: - Policy

    /// 차단 > 숨김 > 스포일러 우선순위로 이 댓글을 어떻게 보여줘야 하는지 결정한다.
    /// 세 플래그는 동시에 여러 개가 `true`일 수 있어, 어느 것을 먼저 보여줄지는 Domain이 정한다.
    public var visibility: CommentVisibility {
        if isBlocked { return .blocked }
        if isHidden { return .hidden }
        if isSpoiler { return .spoiler }
        return .visible
    }
}

public enum CommentVisibility: Equatable, Sendable {
    case blocked
    case hidden
    case spoiler
    case visible
}
