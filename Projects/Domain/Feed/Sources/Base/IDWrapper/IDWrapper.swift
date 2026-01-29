//
//  IDWrapper.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct IDWrapper<Value: Hashable>: Hashable {
    public let value: Value

    public init(_ value: Value) {
        self.value = value
    }
}
