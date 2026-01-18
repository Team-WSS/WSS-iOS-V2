//
//  CharmPoint.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 1/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct CharmPoint: Hashable, Equatable {
    public let name: String
    public init(_ name: String) { self.name = name }
}
