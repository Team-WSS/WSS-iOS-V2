//
//  NovelSearchFilter.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct NovelSearchFilter {
    
    public private(set) var genres: [NovelGenre]
    public private(set) var publicationStatus: NovelPublicationStatus?
    public private(set) var ratingThreshold: NovelRatingThreshold?
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
    
    // - PublicationStatus
    
    public mutating func setPublicationStatus(_ status: NovelPublicationStatus) {
        if publicationStatus == status {
            publicationStatus = nil
        } else {
            publicationStatus = status
        }
    }
    
    public mutating func clearPublicationStatus() {
        publicationStatus = nil
    }
    
    // - RatingThreshold
    
    public mutating func setRatingThreshold(_ threshold: NovelRatingThreshold) {
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
        clearPublicationStatus()
        clearRatingThreshold()
        clearKeywords()
    }
}

