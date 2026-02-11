//
//  NovelDetail.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct NovelDetail {
    
    public let novel: Novel // 기본 정보
    
    public let genres: [NovelGenre]
    public let isCompleted: Bool // 완결 여부
    
    public let feedCount: Int
    
    public let userNovelRating: Float?
    public let userReadStatus: ReadStatus?
    public let userReadStartDate: Date?
    public let userReadEndDate: Date?
    
    public let isUserInterested: Bool // 관심 여부
}
