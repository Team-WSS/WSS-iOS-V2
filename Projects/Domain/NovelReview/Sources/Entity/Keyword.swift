//
//  Keyword.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 1/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct Keyword: Hashable, Equatable {
    public let id: Int
    public let name: String
    
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
