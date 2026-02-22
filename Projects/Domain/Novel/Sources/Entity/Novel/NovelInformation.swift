//
//  NovelInformation.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct NovelInformation {
    // 작품 기본 정보
    public let novel: Novel
    
    // 작품에 대한 유저 평가
    public let userReview: UserNovelReview?
    
    // 작품 정보 탭
    public let description: String
    public let platforms: [NovelPlatform]
    public let attractivePoints: [AttractivePoint]
    public let keywords: [Keyword]
    public let readStatusCount: [ReadStatus : Int]
    
    //MARK: - Policy
    
    public enum ValidationError: Error, Equatable {
        case emptyReadStatus
    }
    
    public func dominantReadStatus() throws -> (status: ReadStatus, count: Int)? {
        guard let dominant = readStatusCount.max(by: { $0.value < $1.value }) else {
            throw ValidationError.emptyReadStatus
        }
        return (dominant.key, dominant.value)
    }
}
