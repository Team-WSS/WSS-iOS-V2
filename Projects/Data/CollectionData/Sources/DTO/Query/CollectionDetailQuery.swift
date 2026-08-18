//
//  CollectionDetailQuery.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

import BaseDomain

public struct CollectionDetailQuery: QueryItemConvertible {
    /// 서버는 `RECENT`/`OLD` 대문자를 받는다. 도메인 `SortType`의 rawValue는 소문자라 여기서 맞춘다.
    public let sortCriteria: String

    public init(sortType: SortType) {
        self.sortCriteria = sortType.rawValue.uppercased()
    }
}
