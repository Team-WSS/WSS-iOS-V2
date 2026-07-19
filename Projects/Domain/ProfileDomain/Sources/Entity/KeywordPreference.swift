//
//  KeywordPreference.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public struct KeywordPreference: Equatable {
    public let keyword: Keyword
    public let count: Int

    public init(
        keyword: Keyword,
        count: Int
    ) {
        self.keyword = keyword
        self.count = count
    }
}
