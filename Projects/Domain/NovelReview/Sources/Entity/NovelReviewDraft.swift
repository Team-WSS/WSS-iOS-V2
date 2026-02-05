//
//  NovelReviewDraft.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct NovelReviewDraft: Equatable {

    public let novelID: NovelID
    public private(set) var status: ReadingStatus
    public private(set) var period: ReadingPeriod?
    public private(set) var rating: Rating?
    public private(set) var attractivePoints: [AttractivePoint]
    public private(set) var keywords: [Keyword]

    // MARK: - Init

    public init(
        novelID: NovelID,
        status: ReadingStatus,
        period: ReadingPeriod?,
        rating: Rating?,
        attractivePoints: [AttractivePoint],
        keywords: [Keyword]
    ) {
        self.novelID = novelID
        self.status = status
        self.period = period
        self.rating = rating
        self.attractivePoints = attractivePoints
        self.keywords = keywords
    }

    // MARK: - Policy
    
    private static let maxAttractivePoints = 3

    public enum ValidationError: Error, Equatable {
        case tooManyAttractivePoints(max: Int)
    }

    // MARK: - Draft Editing

    public mutating func changeStatus(_ newStatus: ReadingStatus) {
        status = newStatus
        period = normalizePeriod(period, for: newStatus)
    }
    
    public mutating func setPeriod(_ newPeriod: ReadingPeriod?) {
        period = normalizePeriod(newPeriod, for: status)
    }
    
    private func normalizePeriod(_ period: ReadingPeriod?, for status: ReadingStatus) -> ReadingPeriod? {
        guard let period else { return nil }

        switch status {
        case .watching:
            guard let start = period.start ?? period.end else { return nil }
            return try! ReadingPeriod(start: start, end: nil)

        case .watched:
            let s = period.start ?? period.end
            let e = period.end ?? period.start
            guard let start = s, let end = e else { return nil }
            return try! ReadingPeriod(start: start, end: end)

        case .quit:
            guard let end = period.end ?? period.start else { return nil }
            return try! ReadingPeriod(start: nil, end: end)
        }
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
    
    public mutating func setKeywords(_ newKeywords: [Keyword]) {
        keywords = newKeywords
    }
    
    public mutating func removeKeyword(_ keyword: Keyword) {
        keywords.removeAll { $0 == keyword }
    }
}
