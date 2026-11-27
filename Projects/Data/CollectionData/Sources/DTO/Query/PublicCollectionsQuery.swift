//
//  PublicCollectionsQuery.swift
//  CollectionData
//
//  Created by YunhakLee on 11/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

import CollectionDomain

/// `GET /collections` 전용 쿼리. 다른 목록과 달리 `sort`가 있어 `CollectionsQuery`를 재사용하지 않는다.
/// nil인 값은 `QueryItemConvertible` 기본 구현이 쿼리에서 알아서 제외한다.
struct PublicCollectionsQuery: QueryItemConvertible {
    /// 최신순은 서버 기본값이라 **생략**해서 보낸다(서버가 받는 값은 `random` 하나뿐, 그 외는 400 COLLECTION-009).
    public let sort: String?
    /// `sort=random`과 함께 보내면 빈 값이어도 400 COLLECTION-007이다 — 무작위 조회에선 nil이어야 한다.
    public let cursor: String?
    public let size: Int

    public init(sort: PublicCollectionSort, cursor: String?, size: Int) {
        switch sort {
        case .latest: self.sort = nil
        case .random: self.sort = "random"
        }
        self.cursor = cursor
        self.size = size
    }
}
