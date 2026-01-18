//
//  ReadingPeriod.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 1/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

public struct ReadingPeriod: Hashable, Equatable {
    public let start: Date?
    public let end: Date?

    public init(start: Date?, end: Date?) {
        self.start = start
        self.end = end
    }
}
