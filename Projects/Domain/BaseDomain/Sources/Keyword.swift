//
//  Keyword.swift
//  BaseDomain
//
//  Created by YunhakLee on 1/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct Keyword: Equatable, Identifiable, Hashable {
    public let id: KeywordID
    public let name: String

    public init(id: KeywordID, name: String) {
        self.id = id
        self.name = name
    }
}
