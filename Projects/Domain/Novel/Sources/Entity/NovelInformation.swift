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

public struct NovelPlatform {
    public let name: String
    public let image: ImageWrapper
    public let url: URL
}

public enum ReadStatus {
    case watching
    case watched
    case quit
}
