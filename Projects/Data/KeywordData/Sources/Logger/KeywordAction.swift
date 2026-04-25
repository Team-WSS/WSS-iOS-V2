//
//  KeywordAction.swift
//  KeywordData
//
//  Created by Seoyeon Choi on 4/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum KeywordAction {
    case searchByText
    case searchByFilter
    
    var text: String {
        switch self {
        case .searchByText: "일반 검색"
        case .searchByFilter: "필터 검색"
        }
    }
}
