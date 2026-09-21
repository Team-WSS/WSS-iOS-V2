//
//  NovelPreference.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct NovelPreference: Sendable {
    public let attractivePoints: [AttractivePoint]
    public let keywords: [KeywordPreference]

    public init(
        attractivePoints: [AttractivePoint],
        keywords: [KeywordPreference]
    ) {
        self.attractivePoints = attractivePoints
        self.keywords = keywords
    }
}
