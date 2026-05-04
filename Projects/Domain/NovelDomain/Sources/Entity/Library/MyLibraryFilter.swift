//
//  MyLibraryFilter.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public struct MyLibraryFilter {
    
    public private(set) var isInterest: Bool
    public private(set) var readingStatus: [ReadingStatus]
    public private(set) var attractivePoint: [AttractivePoint]
    public private(set) var ratingThreshold: NovelRatingThreshold?
    public private(set) var sortType: SortType
    
    public init(
        isInterest: Bool,
        readingStatus: [ReadingStatus],
        attractivePoint: [AttractivePoint],
        ratingThreshold: NovelRatingThreshold? = nil,
        sortType: SortType
    ) {
        self.isInterest = isInterest
        self.readingStatus = readingStatus
        self.attractivePoint = attractivePoint
        self.ratingThreshold = ratingThreshold
        self.sortType = sortType
    }
    
    // MARK: - Policy
    
    // - isInterest
    
    public mutating func toggleInterest() {
        isInterest.toggle()
    }
    
    // - reading status
    
    public mutating func addReadingStatus(_ newStatus: ReadingStatus) {
        guard !readingStatus.contains(newStatus) else { return }
        
        readingStatus.append(newStatus)
    }
    
    public mutating func removeReadingStatus(_ targetReadStatus: ReadingStatus) {
        readingStatus.removeAll { $0 == targetReadStatus }
    }
    
    private mutating func clearReadingStatuses() {
        readingStatus.removeAll()
    }
    
    // - attractive point
    
    public mutating func addAttractivePoint(_ newAttractivePoint: AttractivePoint) {
        guard !attractivePoint.contains(newAttractivePoint) else { return }
        
        attractivePoint.append(newAttractivePoint)
    }
    
    public mutating func removeAttractivePoint(_ targetAttractivePoint: AttractivePoint) {
        attractivePoint.removeAll { $0 == targetAttractivePoint }
    }
    
    private mutating func clearAttractivePoints() {
        attractivePoint.removeAll()
    }
    
    // - RatingThreshold
    
    public mutating func setRatingThreshold(_ threshold: NovelRatingThreshold?) {
        ratingThreshold = threshold
    }
    
    private mutating func clearRatingThreshold() {
        ratingThreshold = nil
    }
    
    // - SortType
    
    public mutating func setSortType(_ sortType: SortType) {
        self.sortType = sortType
    }
    
    // - Clear
    
    public mutating func clearAll() {
        clearReadingStatuses()
        clearAttractivePoints()
        clearRatingThreshold()
    }
}
