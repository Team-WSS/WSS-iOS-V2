//
//  RecentSearchWord.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public struct RecentSearchWord: Sendable {
    public let id: SearchWordID
    public let title: String
    
    public init(id: SearchWordID,
                title: String) {
        self.id = id
        self.title = title
    }
}
