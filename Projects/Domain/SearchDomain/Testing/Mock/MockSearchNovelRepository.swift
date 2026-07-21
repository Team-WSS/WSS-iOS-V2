//
//  MockSearchNovelRepository.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import SearchDomain
import BaseDomain

public final class MockSearchNovelRepository: SearchNovelRepository {

    public var searchByTextResult: Result<(Paginated<Novel>, Int), RepositoryError>!
    public var searchByFilterResult: Result<(Paginated<Novel>, Int), RepositoryError>!

    public private(set) var searchByTextCallCount = 0
    public private(set) var lastSearchQuery: String?
    public private(set) var lastSearchTextPage: Int?
    public private(set) var searchByFilterCallCount = 0
    public private(set) var lastSearchFilter: SearchFilter?
    public private(set) var lastSearchFilterPage: Int?

    public init() {}

    public func searchNovelByText(_ text: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        searchByTextCallCount += 1
        lastSearchQuery = text
        lastSearchTextPage = page
        return try searchByTextResult.get()
    }

    public func searchNovelByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        searchByFilterCallCount += 1
        lastSearchFilter = filter
        lastSearchFilterPage = page
        return try searchByFilterResult.get()
    }
}
