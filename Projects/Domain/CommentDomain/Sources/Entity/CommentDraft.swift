//
//  CommentDraft.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct CommentDraft: Sendable {
    
    public private(set) var content: String
    
    // MARK: - init
    
    public init(content: String) {
#if DEBUG
        if content.count > Self.maxContentCount {
            assertionFailure("Content overflow: \(content.count) (max: \(Self.maxContentCount))")
        }
#endif
        
        self.content = content
    }
    
    // MARK: - Policy
    
    /// 댓글 본문 최대 길이. 입력 단계에서 이 값으로 clamp해야 한다 — 넘긴 채 `init`이 불리면
    /// DEBUG 빌드에서 `assertionFailure`로 죽는다(입력 화면이 `FeedDetailCommentInputBar`).
    public static let maxContentCount: Int = 500
    
    public enum ValidationError: Error, Equatable {
        case emptyContent
        case contentOverLimit
    }
    
    public mutating func updateContent(_ newValue: String) throws {
        guard !newValue.isEmpty else {
            throw ValidationError.emptyContent
        }

        guard newValue.count <= Self.maxContentCount else {
            throw ValidationError.contentOverLimit
        }

        content = newValue
    }
}
