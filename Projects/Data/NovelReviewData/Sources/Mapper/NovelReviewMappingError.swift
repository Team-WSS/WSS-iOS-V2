//
//  NovelReviewMapperError.swift
//  NovelReviewData
//
//  Created by YunhakLee on 3/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


enum MappingError: Error, Equatable, CustomStringConvertible {
    case invalidConversion(type: ConversionType, rawValue: String)
    case invalidPayload(reason: InvalidPayloadReason)
    
    var description: String {
        switch self {
        case let .invalidConversion(type, rawValue):
            return "[MappingError] invalid \(type) from '\(rawValue)'"
            
        case let .invalidPayload(reason):
            return "[MappingError] invalid payload: \(reason)"
        }
    }
}

enum InvalidPayloadReason: Equatable, CustomStringConvertible {
    case duplicatedAttractivePoints
    case tooManyAttractivePoints
    case duplicatedKeywords
    case tooManyKeywords
    
    var description: String {
        switch self {
        case .duplicatedAttractivePoints:
            return "duplicated attractivePoints"
        case .tooManyAttractivePoints:
            return "too many attractivePoints"
        case .duplicatedKeywords:
            return "duplicated keywords"
        case .tooManyKeywords:
            return "too many keywords"
        }
    }
}

enum ConversionType: CustomStringConvertible {
    case readingStatus, attractivePoint, startDate, endDate
    
    var description: String {
        switch self {
        case .readingStatus: return "ReadingStatus"
        case .attractivePoint: return "AttractivePoint"
        case .startDate: return "StartDate"
        case .endDate: return "EndDate"
        }
    }
}
