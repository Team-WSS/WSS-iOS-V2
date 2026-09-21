//
//  CollectionsQuery.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

/// nil인 cursor는 `QueryItemConvertible` 기본 구현이 쿼리에서 알아서 제외한다.
struct CollectionsQuery: QueryItemConvertible {
    /// 직전 응답의 `nextCursor`. 첫 페이지는 nil이며, 서버가 발급한 값을 그대로 되돌려 보낸다.
    public let cursor: String?
    public let size: Int

    public init(cursor: String?, size: Int) {
        self.cursor = cursor
        self.size = size
    }
}
