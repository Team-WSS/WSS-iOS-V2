//
//  BirthYear.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public struct BirthYear: Equatable {
    public let value: Int
    
    static public let minYear = 1900
    static public let maxYear = 2024
    
    public init(_ value: Int) throws {
        guard (Self.minYear...Self.maxYear).contains(value) else {
            throw ValidationError.invalidRange
        }
        self.value = value
    }
    
    public enum ValidationError: Error {
        case invalidRange
    }
}
