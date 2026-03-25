//
//  NovelReviewDataMapper.swift
//  NovelReviewData
//
//  Created by YunhakLee on 3/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import NovelReviewDomain
import BaseDomain

enum NovelReviewMapper {
    
    enum MappingError: Error, Equatable {
        case invalidConversion(type: String, rawValue: String)
        case invalidPayload(reason: InvalidPayloadReason)
    }
    
    enum InvalidPayloadReason: Equatable {
        case duplicatedAttractivePoints
        case tooManyAttractivePoints
        case duplicatedKeywords
        case tooManyKeywords
    }
    
    static func novelReviewDraft(
           from review: NovelReviewResponse,
           novelID: NovelID
       ) throws -> NovelReviewDraft? {
           guard let status = try readingStatus(from: review.status) else {
               return nil
           }

           let period = try readingPeriod(
               startDate: review.startDate,
               endDate: review.endDate
           )
           
           let ratingSource = review.userNovelRating == 0.0 ? nil: Double(review.userNovelRating)
           let rating = try rating(from: ratingSource)

           let attractivePoints = try review.attractivePoints.map {
               try attractivePoint(from: $0)
           }

           let keywords = review.keywords.map {
               Keyword(id: KeywordID($0.keywordId), name: $0.keywordName)
           }

           if Set(attractivePoints).count != attractivePoints.count {
               throw MappingError.invalidPayload(reason: .duplicatedAttractivePoints)
           }

           if attractivePoints.count > NovelReviewDraft.maxAttractivePoints {
               throw MappingError.invalidPayload(reason: .tooManyAttractivePoints)
           }

           if Set(keywords).count != keywords.count {
               throw MappingError.invalidPayload(reason: .duplicatedKeywords)
           }

           if keywords.count > NovelReviewDraft.maxKeywords {
               throw MappingError.invalidPayload(reason: .tooManyKeywords)
           }

           return NovelReviewDraft(
               novelID: novelID,
               status: status,
               period: period,
               rating: rating,
               attractivePoints: attractivePoints,
               keywords: keywords
           )
       }
    
    static func postNovelReviewRequest(
        from draft: NovelReviewDraft
    ) -> PostNovelReviewRequest {
        PostNovelReviewRequest(
            novelId: draft.novelID.value,
            userNovelRating: Float(draft.rating?.value ?? 0.0),
            status: readingStatusString(from: draft.status),
            startDate: DateParser.dateString(from: draft.period?.start),
            endDate: DateParser.dateString(from: draft.period?.end),
            attractivePoints: draft.attractivePoints.map{attractivePointString(from: $0)} ,
            keywordIds: draft.keywords.map{ $0.id.value })
    }
    
    static func putNovelReviewRequest(
        from draft: NovelReviewDraft
    ) -> PutNovelReviewRequest {
        PutNovelReviewRequest(
            userNovelRating: Float(draft.rating?.value ?? 0.0),
            status: readingStatusString(from: draft.status),
            startDate: DateParser.dateString(from: draft.period?.start),
            endDate: DateParser.dateString(from: draft.period?.end),
            attractivePoints: draft.attractivePoints.map { attractivePointString(from: $0) },
            keywordIds: draft.keywords.map { $0.id.value }
        )
    }
}

extension NovelReviewMapper {
    
    // MARK: - DTO -> Entity Helper
    
    static private func readingStatus(
        from text: String?
    ) throws -> ReadingStatus? {
        guard let text else { return nil }
        
        switch text {
        case "WATCHING": return .watching
        case "WATCHED": return .watched
        case "QUIT": return .quit
        default: throw MappingError.invalidConversion(type: "ReadingStatus",
                                                      rawValue: text)
        }
    }
    
    static private func readingPeriod(
        startDate: String?,
        endDate: String?
    ) throws -> ReadingPeriod? {
        if startDate == nil && endDate == nil {
            return nil
        }
        var start: Date? = nil
        var end: Date? = nil
        
        if let startDate {
            guard let parsed = DateParser.date(from: startDate) else {
                throw MappingError.invalidConversion(type: "ReadingPeriod",
                                                     rawValue: startDate)
            }
            start = parsed
        }
        if let endDate {
            guard let parsed = DateParser.date(from: endDate) else {
                throw MappingError.invalidConversion(type: "ReadingPeriod",
                                                     rawValue: endDate)
            }
            end = parsed
        }
        
        return try ReadingPeriod(start: start, end: end)
    }
    
    static private func rating(
        from rating: Double?
    ) throws -> Rating? {
        guard let rating else { return nil }
        return try Rating(rating)
    }
    
    static private func attractivePoint(
        from text: String
    ) throws -> AttractivePoint {
        switch text {
        case "worldview": return .worldview
        case "material": return .material
        case "character": return .character
        case "relationship": return .relationship
        case "vibe": return .vibe
        case "writingskill": return .writingSkill
        default: throw MappingError.invalidConversion(type: "AttractivePoint",
                                                      rawValue: text)
        }
    }
    
    // MARK: - Entity -> DTO Helper
    
    static private func readingStatusString(
        from status: ReadingStatus
    ) -> String {
        switch status {
        case .quit: return "QUIT"
        case .watching: return "WATCHING"
        case .watched: return "WATCHED"
        }
    }
    
    static private func attractivePointString(
        from point: AttractivePoint
    ) -> String {
        switch point {
        case .worldview: return "worldview"
        case .material: return "material"
        case .character: return "character"
        case .relationship: return "relationship"
        case .vibe: return "vibe"
        case .writingSkill: return "writingskill"
        }
    }
}

