//
//  PaginatedWrapper.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 1/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct Paginated<T> {
    public let items: [T]
    public let hasNext: Bool
    
    public init(items: [T], hasNext: Bool) {
        self.items = items
        self.hasNext = hasNext
    }
}
