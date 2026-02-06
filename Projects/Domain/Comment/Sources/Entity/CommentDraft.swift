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
    
    //MARK: - Policy
    
    static let maxContentCount: Int = 500
    
    public enum PolicyError: Error, Equatable {
        case emptyContent
        case contentOverLimit
    }
    
    public mutating func updateContent(_ newValue: String) throws {
        guard newValue.count <= Self.maxContentCount else {
            throw PolicyError.contentOverLimit
        }
        
        content = newValue
    }
    
    public mutating func validateForSubmission() throws(PolicyError) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedContent.isEmpty {
            throw .emptyContent
        }
    }
}
