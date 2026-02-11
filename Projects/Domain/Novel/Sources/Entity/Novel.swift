//
//  Novel.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct Novel {
    
    public let id: NovelID
    
    public let thumbnailImage: ImageWrapper
    public let title: String // 웹소설 제목
    public let author: [String] // 웹소설 작가
    
    public private(set) var interestCount: Int // 관심 수
    public private(set) var novelRating: Float // 별점
    public private(set) var novelRatingCount: Int // 별점 수 
}
