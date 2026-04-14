//
//  LibraryFilter.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

// 타유저 서재 조회시 필터

public struct LibraryFilter {
    
    public private(set) var sortType: SortType
    
    // MARK: - Policy
    
    public mutating func setSortType(_ sortType: SortType) {
        self.sortType = sortType
    }
}
