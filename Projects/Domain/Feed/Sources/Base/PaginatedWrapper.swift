//
//  PaginatedWrapper.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct Paginated<T> {
    public let items: [T]
    public let hasNext: Bool
}
