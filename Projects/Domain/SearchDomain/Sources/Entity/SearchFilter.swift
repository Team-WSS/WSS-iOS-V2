//
//  SearchFilter.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct SearchFilter {
    
    public private(set) var genres: [NovelGenre]
    public private(set) var platforms: [NovelPlatform]
    public private(set) var publicationStatus: NovelPublicationStatus?
    public private(set) var ratingThreshold: NovelRatingThreshold?
    public private(set) var ratingRange: NovelRatingRange?
    public private(set) var keywords: [Keyword]

    public init(
        genres: [NovelGenre] = [],
        platforms: [NovelPlatform] = [],
        publicationStatus: NovelPublicationStatus? = nil,
        ratingThreshold: NovelRatingThreshold? = nil,
        ratingRange: NovelRatingRange? = nil,
        keywords: [Keyword] = []
    ) {
        self.genres = genres
        self.platforms = platforms
        self.publicationStatus = publicationStatus
        self.ratingThreshold = ratingThreshold
        self.ratingRange = ratingRange
        self.keywords = keywords
    }
    
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

    // - platforms (플랫폼)

    public mutating func addPlatform(_ newPlatform: NovelPlatform) {
        guard !platforms.contains(newPlatform) else { return }

        platforms.append(newPlatform)
    }

    public mutating func removePlatform(_ targetPlatform: NovelPlatform) {
        platforms.removeAll { $0 == targetPlatform }
    }

    private mutating func clearPlatforms() {
        platforms.removeAll()
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

    // - RatingRange (별점 범위, 상세탐색 필터 전용)

    /// 별점 범위를 설정한다. 경계를 벗어나면 경계로 보정하고, min > max면 무시한다.
    /// 전체 범위(0.0~5.0)는 "필터 없음"과 같은 뜻이므로 nil로 정규화한다(`NovelDomain.MyLibraryFilter`와 동일 규칙).
    public mutating func setRatingRange(min: Float, max: Float) {
        let bounds = NovelRatingRange.bounds
        let clampedMin = Swift.min(Swift.max(min, bounds.lowerBound), bounds.upperBound)
        let clampedMax = Swift.min(Swift.max(max, bounds.lowerBound), bounds.upperBound)
        guard clampedMin <= clampedMax else { return }

        if clampedMin == bounds.lowerBound && clampedMax == bounds.upperBound {
            ratingRange = nil
        } else {
            ratingRange = NovelRatingRange(min: clampedMin, max: clampedMax)
        }
    }

    private mutating func clearRatingRange() {
        ratingRange = nil
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
        clearPlatforms()
        clearPublicationStatus()
        clearRatingThreshold()
        clearRatingRange()
        clearKeywords()
    }
}
