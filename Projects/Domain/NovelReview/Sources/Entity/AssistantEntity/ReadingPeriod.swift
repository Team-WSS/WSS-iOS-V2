//
//  ReadingPeriod.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 1/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

public struct ReadingPeriod: Equatable {
    public let start: Date?
    public let end: Date?
    
    // MARK: - Policy

    public init(start: Date?, end: Date?) throws {
        if let start, let end {
            guard start <= end else {
                throw ValidationError.startAfterEnd
            }
        }
        self.start = start
        self.end = end
    }

    public enum ValidationError: Error, Equatable {
        case startAfterEnd
    }
}
