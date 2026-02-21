//
//  NovelSearchFilter.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public enum CompletionStatus: Equatable {
    case completed
    case onGoing
}

public enum RatingThreshold: Float, CaseIterable, Equatable {
    case over3_5 = 3.5
    case over4_0 = 4.0
    case over4_5 = 4.5
    case over4_8 = 4.8
}

public struct NovelSearchFilter {
    
    public private(set) var genres: [NovelGenre]
    public private(set) var completionStatus: CompletionStatus?
    public private(set) var ratingThreshold: RatingThreshold?
    public private(set) var keywords: [Keyword]
    
    //MARK: - Policy
    
    public enum ValidationError: Error, Equatable {
        case keywordOverLimit(max: Int)
    }
    
    // - genres
    
    public mutating func addGenre(_ newGenre: NovelGenre) {
        guard !genres.contains(newGenre) else { return }
        
        genres.append(newGenre)
    }
    
    public mutating func removeGenre(_ targetGenre: NovelGenre) {
        genres.removeAll { $0 == targetGenre }
    }
    
    public mutating func clearGenres() {
        genres.removeAll()
    }
    
    // - Completion
    
    public mutating func setCompletion(_ status: CompletionStatus) {
        if completionStatus == status {
            completionStatus = nil
        } else {
            completionStatus = status
        }
    }
    
    public mutating func clearCompletion() {
        completionStatus = nil
    }
    
    // - RatingThreshold
    
    public mutating func setRatingThreshold(_ threshold: RatingThreshold) {
        if ratingThreshold == threshold {
            ratingThreshold = nil
        } else {
            ratingThreshold = threshold
        }
    }
    
    public mutating func clearRatingThreshold() {
        ratingThreshold = nil
    }
    
    // - Keyword
    
    private static let maxKeywordCount = 20
    
    public mutating func setKeywords(_ newKeywords: [Keyword]) throws {
        guard newKeywords.count <= Self.maxKeywordCount else {
            throw ValidationError.keywordOverLimit(max: Self.maxKeywordCount)
        }
        
        keywords = newKeywords
    }
    
    public mutating func removeKeyword(_ keyword: Keyword) {
        keywords.removeAll { $0 == keyword }
    }
    
    public mutating func clearKeywords() {
        keywords.removeAll()
    }
    
    // - Clear
    
    public mutating func clearAll() {
        clearGenres()
        clearCompletion()
        clearRatingThreshold()
        clearKeywords()
    }
}

