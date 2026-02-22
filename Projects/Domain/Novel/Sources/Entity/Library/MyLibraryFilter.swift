//
//  MyLibraryFilter.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct MyLibraryFilter {
    
    public private(set) var readStatus: [ReadingStatus]
    public private(set) var attractivePoint: [AttractivePoint]
    public private(set) var ratingThreshold: NovelRatingThreshold?
    
    // MARK: - Policy
    
    // - readStatus
    
    public mutating func addReadStatus(_ newStatus: ReadingStatus) {
        guard !readStatus.contains(newStatus) else { return }
        
        readStatus.append(newStatus)
    }
    
    public mutating func removeGenre(_ targetReadStatus: ReadingStatus) {
        readStatus.removeAll { $0 == targetReadStatus }
    }
    
    public mutating func clearReadStatuses() {
        readStatus.removeAll()
    }
    
    // - attractivePoint
    
    public mutating func addAttractivePoint(_ newAttractivePoint: AttractivePoint) {
        guard !attractivePoint.contains(newAttractivePoint) else { return }
        
        attractivePoint.append(newAttractivePoint)
    }
    
    public mutating func removeGenre(_ targetAttractivePoint: AttractivePoint) {
        attractivePoint.removeAll { $0 == targetAttractivePoint }
    }
    
    public mutating func clearAttractivePoints() {
        attractivePoint.removeAll()
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
    
    // - Clear
    
    public mutating func clearAll() {
        clearReadStatuses()
        clearAttractivePoints()
        clearRatingThreshold()
    }
}
