//
//  MockMyLibraryFilterRepository.swift
//  NovelDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NovelDomain
import BaseDomain

public final class MockMyLibraryFilterRepository: MyLibraryFilterRepository {

    public var storedFilter: MyLibraryFilter?
    public private(set) var savedFilters: [MyLibraryFilter] = []
    public private(set) var loadCallCount = 0

    public init(storedFilter: MyLibraryFilter? = nil) {
        self.storedFilter = storedFilter
    }

    public func loadFilter() -> MyLibraryFilter? {
        loadCallCount += 1
        return storedFilter
    }

    public func saveFilter(_ filter: MyLibraryFilter) {
        savedFilters.append(filter)
        storedFilter = filter
    }
}
