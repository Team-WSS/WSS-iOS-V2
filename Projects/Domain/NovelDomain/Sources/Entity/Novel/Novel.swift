//
//  Novel.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct Novel {
    
    public let id: NovelID
    
    public let thumbnailImage: URL?
    public let title: String
    public let authors: [String]
    
    public private(set) var interestCount: Int
    public let rating: Float
    public let ratingCount: Int
    
    public private(set) var isInterested: Bool?
    
    public init(
        id: NovelID,
        thumbnailImage: URL?,
        title: String,
        authors: [String],
        interestCount: Int,
        rating: Float,
        ratingCount: Int,
        isInterested: Bool? = nil
    ) {
        self.id = id
        self.thumbnailImage = thumbnailImage
        self.title = title
        self.authors = authors
        self.interestCount = interestCount
        self.rating = rating
        self.ratingCount = ratingCount
        self.isInterested = isInterested
    }
    
    // MARK: - Policy
    
    public mutating func markAsInterested() {
        guard isInterested == false else { return }
        isInterested = true
        interestCount += 1
    }
    
    public mutating func unmarkAsInterested() {
        guard isInterested == true else { return }
        isInterested = false
        interestCount = max(0, interestCount - 1)
    }
    
    public mutating func toggleInterest() {
        if isInterested == true {
            unmarkAsInterested()
        } else {
            markAsInterested()
        }
    }
}
