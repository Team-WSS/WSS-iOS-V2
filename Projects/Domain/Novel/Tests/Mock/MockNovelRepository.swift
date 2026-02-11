//
//  MockNovelRepository.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import NovelDomain
import BaseDomain

final class MockNovelRepository: NovelRepository {

    var fetchDetailResult: Result<NovelDetail, Error>!
    var fetchInformationResult: Result<NovelInformation, Error>!
    var searchByTextResult: Result<Paginated<Novel>, Error>!
    var searchByFilterResult: Result<Paginated<Novel>, Error>!

    private(set) var fetchDetailCallCount = 0
    private(set) var fetchInformationCallCount = 0
    private(set) var searchByTextCallCount = 0
    private(set) var searchByFilterCallCount = 0

    private(set) var lastFetchedDetailID: NovelID?
    private(set) var lastFetchedInformationID: NovelID?
    private(set) var lastSearchQuery: String?
    private(set) var lastSearchFilter: NovelSearchFilter?

    func fetchNovelDetail(id: NovelID) async throws -> NovelDetail {
        fetchDetailCallCount += 1
        lastFetchedDetailID = id
        return try fetchDetailResult.get()
    }

    func fetchNovelInformation(id: NovelID) async throws -> NovelInformation {
        fetchInformationCallCount += 1
        lastFetchedInformationID = id
        return try fetchInformationResult.get()
    }

    func searchNovelByText(_ text: String) async throws -> Paginated<Novel> {
        searchByTextCallCount += 1
        lastSearchQuery = text
        return try searchByTextResult.get()
    }

    func searchNovelByFilter(_ filter: NovelSearchFilter) async throws -> Paginated<Novel> {
        searchByFilterCallCount += 1
        lastSearchFilter = filter
        return try searchByFilterResult.get()
    }
}
