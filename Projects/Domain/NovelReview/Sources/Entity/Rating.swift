//
//  Rating.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 1/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct Rating: Hashable, Equatable {
    public let value: Double
    
    public init(_ value: Double) throws {
        guard value >= 0.5 && value <= 5.0 else { throw Error.outOfRange }
        let scaled = value * 2
        guard abs(scaled.rounded() - scaled) < 0.000001 else { throw Error.invalidStep }
        self.value = value
    }
    
    public enum Error: Swift.Error, Equatable {
        case outOfRange
        case invalidStep
    }
}
