//
//  NovelReviewDraft.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct NovelReviewDraft: Equatable {
    
    public let novelID: NovelID
    public private(set) var status: ReadingStatus
    public private(set) var period: ReadingPeriod?
    public private(set) var rating: Rating?
    public private(set) var attractivePoints: [AttractivePoint]
    public private(set) var keywords: [Keyword]
    
    // MARK: - Policy
    
    private static let maxAttractivePoints = 3
    private static let maxKeywords = 20
    
    public enum ValidationError: Error, Equatable {
        case tooManyAttractivePoints(max: Int)
        case tooManyKeywords(max: Int)
    }
    
    // MARK: - Init
    
    public init(
        novelID: NovelID,
        status: ReadingStatus,
        period: ReadingPeriod?,
        rating: Rating?,
        attractivePoints: [AttractivePoint],
        keywords: [Keyword]
    ) {
        let uniqueAttractivePoints = Array(Set(attractivePoints))
        let uniqueKeywords = Array(Set(keywords))
#if DEBUG
        if uniqueAttractivePoints.count != attractivePoints.count {
            assertionFailure("AttractivePoints contains duplicates")
        }
        if uniqueKeywords.count != keywords.count {
            assertionFailure("Keywords contains duplicates")
        }
        if uniqueAttractivePoints.count > Self.maxAttractivePoints {
            assertionFailure("AttractivePoints overflow: \(uniqueAttractivePoints.count) (max: \(Self.maxAttractivePoints))")
        }
        if uniqueKeywords.count > Self.maxKeywords {
            assertionFailure("Keywords overflow: \(uniqueKeywords.count) (max: \(Self.maxKeywords))")
        }
#endif
        
        self.novelID = novelID
        self.status = status
        self.period = period?.normalized(for: status)
        self.rating = rating
        self.attractivePoints = Array(uniqueAttractivePoints.prefix(Self.maxAttractivePoints))
        self.keywords = Array(uniqueKeywords.prefix(Self.maxKeywords))
    }
    
    // MARK: - Draft Editing
    
    public mutating func changeStatus(_ newStatus: ReadingStatus) {
        status = newStatus
        period = period?.normalized(for: newStatus)
    }
    
    public mutating func setPeriod(_ newPeriod: ReadingPeriod?) {
        period = newPeriod?.normalized(for: status)
    }
    
    public mutating func setRating(_ newRating: Rating?) {
        rating = newRating
    }
    
    public mutating func addAttractivePoint(_ point: AttractivePoint) throws {
        guard !attractivePoints.contains(point) else {
            return
        }
        guard attractivePoints.count < Self.maxAttractivePoints else {
            throw ValidationError.tooManyAttractivePoints(max: Self.maxAttractivePoints)
        }
        attractivePoints.append(point)
    }
    
    public mutating func removeAttractivePoint(_ point: AttractivePoint) {
        attractivePoints.removeAll { $0 == point }
    }
    
    public mutating func setKeywords(_ newKeywords: [Keyword]) throws {
        let uniqueKeywords = Array(Set(newKeywords))
#if DEBUG
        if uniqueKeywords.count != newKeywords.count {
            assertionFailure("Keywords contains duplicates")
        }
#endif
        guard uniqueKeywords.count <= Self.maxKeywords else {
            throw ValidationError.tooManyKeywords(max: Self.maxKeywords)
        }
        keywords = uniqueKeywords
    }
    
    public mutating func removeKeyword(_ keyword: Keyword) {
        keywords.removeAll { $0 == keyword }
    }
}
