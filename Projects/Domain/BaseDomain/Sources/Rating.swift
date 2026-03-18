//
//  Rating.swift
//  BaseDomain
//
//  Created by YunhakLee on 1/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct Rating: Equatable {
    public let value: Double
    
    // MARK: - Policy
    
    public init(_ value: Double) throws {
        guard value >= 0.5 && value <= 5.0 else { throw ValidationError.outOfRange }
        let scaled = value * 2
        guard abs(scaled.rounded() - scaled) < 0.000001 else { throw ValidationError.invalidStep }
        self.value = value
    }
    
    public enum ValidationError: Error, Equatable {
        case outOfRange
        case invalidStep
    }
}
