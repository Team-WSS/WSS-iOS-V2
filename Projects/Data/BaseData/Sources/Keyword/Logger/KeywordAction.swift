//
//  KeywordAction.swift
//  BaseData
//
//  Created by Seoyeon Choi on 4/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

enum KeywordAction {
    case searchByText
    case searchByFilter(query: String)
    case sync

    var text: String {
        switch self {
        case .searchByText: "일반 검색"
        case .searchByFilter(let query): "필터 검색 query: '\(query)'"
        case .sync: "키워드 동기화"
        }
    }
}
