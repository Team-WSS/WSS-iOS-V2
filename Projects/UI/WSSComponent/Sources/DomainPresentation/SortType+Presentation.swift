//
//  SortType.swift
//  WSSComponent
//
//  Created by YunhakLee on 5/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import SwiftUI
import DesignSystem

public extension SortType {
    var displayName: String {
        switch self {
        case .recent:
            return "최신 순"
        case .old:
            return "오래된 순"
        }
    }
}
