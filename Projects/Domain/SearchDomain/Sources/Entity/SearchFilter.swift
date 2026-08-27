//
//  SearchFilter.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct SearchFilter: Sendable {
    
    public private(set) var genres: [NovelGenre]
    public private(set) var platforms: [NovelPlatform]
    public private(set) var publicationStatus: NovelPublicationStatus?
    public private(set) var ratingRange: NovelRatingRange?
    public private(set) var keywords: [Keyword]

    public init(
        genres: [NovelGenre] = [],
        platforms: [NovelPlatform] = [],
        publicationStatus: NovelPublicationStatus? = nil,
        ratingRange: NovelRatingRange? = nil,
        keywords: [Keyword] = []
    ) {
        self.genres = genres
        self.platforms = platforms
        self.publicationStatus = publicationStatus
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
    
    /// 키워드 선택 결과를 일괄 반영한다(키워드 탭에서 선택이 바뀔 때마다 등). 개별 `addKeyword`와 달리
    /// 에러를 던지지 않고 최대 개수를 넘는 나머지는 조용히 잘라낸다 — 호출부 UI가 이미 선택을 허용한
    /// 값이라 여기서 다시 막을 이유가 없다.
    public mutating func setKeywords(_ newKeywords: [Keyword]) {
        keywords = Array(newKeywords.prefix(Self.maxKeywordCount))
    }

    public mutating func removeKeyword(_ keyword: Keyword) {
        keywords.removeAll { $0 == keyword }
    }

    public mutating func clearKeywords() {
        keywords.removeAll()
    }

    // - Clear

    /// 상세탐색 필터 화면의 "정보" 탭 4종(장르·플랫폼·연재상태·별점 범위)만 초기화한다. 키워드는
    /// 별개 탭 소관이라 포함하지 않는다 — 탭별로 "초기화"가 각자 독립적으로 동작해야 해서 나뉘었다(#185, 사용자 확정).
    public mutating func clearInfoFilters() {
        clearGenres()
        clearPlatforms()
        clearPublicationStatus()
        clearRatingRange()
    }

    public mutating func clearAll() {
        clearGenres()
        clearPlatforms()
        clearPublicationStatus()
        clearRatingRange()
        clearKeywords()
    }
}
