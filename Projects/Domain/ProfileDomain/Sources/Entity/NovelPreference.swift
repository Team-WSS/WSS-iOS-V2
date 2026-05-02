//
//  NovelPreference.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct NovelPreference {
    public let attractivePoints: [AttractivePoint]
    public let keywords: [Keyword : Int]
    
    public init(
        attractivePoints: [AttractivePoint],
        keywords: [Keyword : Int]
    ) {
        self.attractivePoints = attractivePoints
        self.keywords = keywords
    }
}
