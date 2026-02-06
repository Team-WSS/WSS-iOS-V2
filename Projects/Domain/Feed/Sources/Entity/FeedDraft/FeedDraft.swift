//
//  FeedDraft.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct FeedDraft {
    
    public private(set) var content: String
    public private(set) var genre: [NovelGenre]
    public private(set) var isSpoiler: Bool
    public private(set) var isPrivate: Bool
    public private(set) var connectedNovel: ConnectedNovel?
    public private(set) var attachedImages: [ImageWrapper]
    
    //MARK: - Policy
    
    static let maxContentCount: Int = 2000
    
    public enum PolicyError: Error, Equatable {
        case contentOverLimit
        case emptyContent
        case emptyGenre
    }
    
    public mutating func updateContent(_ newValue: String) throws {
        guard newValue.count <= Self.maxContentCount else {
            throw PolicyError.contentOverLimit
        }
        
        content = newValue
    }
    
    public mutating func selectGenre(_ newGenre: NovelGenre) {
        guard !genre.contains(newGenre) else { return }
        genre.append(newGenre)
    }
    
    public mutating func deselectGenre(_ targetGenre: NovelGenre) {
        genre.removeAll { $0 == targetGenre }
    }
    
    public mutating func selectPrivate(_ isSelected: Bool) {
        isPrivate = isSelected
    }
    
    public mutating func selectSpoiler(_ isSelected: Bool) {
        isSpoiler = isSelected
    }
        
    public mutating func validateForSubmission() throws(PolicyError) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedContent.isEmpty {
            throw .emptyContent
        }
        
        if genre.isEmpty {
            throw .emptyGenre
        }
    }
}
