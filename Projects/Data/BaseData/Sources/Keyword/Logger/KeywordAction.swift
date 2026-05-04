//
//  KeywordAction.swift
//  BaseData
//
//  Created by Seoyeon Choi on 4/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

enum KeywordAction {
    case fetchAll
    case searchByFilter(query: String)
    case sync

    var text: String {
        switch self {
        case .fetchAll: "키워드 전체 조회"
        case .searchByFilter(let query): "키워드 검색 query: '\(query)'"
        case .sync: "키워드 동기화"
        }
    }
}
