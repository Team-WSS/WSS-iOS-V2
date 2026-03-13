//
//  CommentDraft.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct CommentDraft {
    
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
    
    static let maxContentCount: Int = 500
    
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
