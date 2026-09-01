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
    /// 서버가 내려주는 **전체 개수**(현재 로드된 `items.count`가 아니라 페이지네이션 이전의 총량).
    /// 이 값을 주는 응답에서만 채워진다 — 내 피드 목록(`feedsCount`)이 첫 소비자이고, 커서 목록 대부분은 `nil`.
    public let totalCount: Int?

    public init(items: [T], hasNext: Bool, totalCount: Int? = nil) {
        self.items = items
        self.hasNext = hasNext
        self.totalCount = totalCount
    }
}

extension Paginated: Sendable where T: Sendable {}
