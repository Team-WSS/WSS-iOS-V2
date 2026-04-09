//
//  KeywordGroup.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct KeywordGroup {
    public let name: String
    public let profileImage: ImageWrapper
    public let keywords: [Keyword]
}
