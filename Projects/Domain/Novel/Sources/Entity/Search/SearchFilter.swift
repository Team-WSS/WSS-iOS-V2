//
//  SearchFilter.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct SearchFilter {
    
    public private(set) var genres: [NovelGenre]
    public private(set) var publicationStatus: NovelPublicationStatus?
    public private(set) var ratingThreshold: NovelRatingThreshold?
    public private(set) var keywords: [Keyword]
    
    // MARK: - Policy
    
    public enum ValidationError: Error, Equatable {
        case keywordOverLimit(max: Int)
    }
    
    // - genres (장르)
    
    public mutating func addGenre(_ newGenre: NovelGenre) {
        guard !genres.contains(newGenre) else { return }
        
        genres.append(newGenre)
    }
    
    public mutating func removeGenre(_ targetGenre: NovelGenre) {
        genres.removeAll { $0 == targetGenre }
    }
    
    private mutating func clearGenres() {
        genres.removeAll()
    }
    
    // - PublicationStatus (연재상태)
    
    public mutating func setPublicationStatus(_ status: NovelPublicationStatus?) {
        publicationStatus = status
    }
    
    private mutating func clearPublicationStatus() {
        publicationStatus = nil
    }
    
    // - RatingThreshold (별점)
    
    public mutating func setRatingThreshold(_ threshold: NovelRatingThreshold?) {
        ratingThreshold = threshold
    }
    
    private mutating func clearRatingThreshold() {
        ratingThreshold = nil
    }
    
    // - Keyword (키워드)
    
    private static let maxKeywordCount = 20
    
    public mutating func addKeyword(_ newKeyword: Keyword) throws {
        guard keywords.count < Self.maxKeywordCount else {
            throw ValidationError.keywordOverLimit(max: Self.maxKeywordCount)
        }
        
        keywords.append(newKeyword)
    }
    
    public mutating func removeKeyword(_ keyword: Keyword) {
        keywords.removeAll { $0 == keyword }
    }
    
    private mutating func clearKeywords() {
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
