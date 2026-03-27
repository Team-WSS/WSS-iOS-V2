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

public final class MockNovelRepository: NovelRepository {

    public var fetchNovelResult: Result<NovelInformation, RepositoryError>!
    public var addInterestResult: Result<Void, RepositoryError> = .success(())
    public var removeInterestResult: Result<Void, RepositoryError> = .success(())
    public var searchByTextResult: Result<(Paginated<Novel>, Int), RepositoryError>!
    public var searchByFilterResult: Result<(Paginated<Novel>, Int), RepositoryError>!
    public var fetchMyLibraryResult: Result<(Paginated<LibraryNovel>, Int), RepositoryError>!
    public var fetchUserLibraryResult: Result<(Paginated<LibraryNovel>, Int), RepositoryError>!
    public var fetchRegisteredNovelStatsResult: Result<RegisteredNovelStats, RepositoryError>!

    public private(set) var fetchedNovelIDs: [NovelID] = []
    public private(set) var addedInterestIDs: [NovelID] = []
    public private(set) var removedInterestIDs: [NovelID] = []
    public private(set) var searchByTextCallCount = 0
    public private(set) var lastSearchQuery: String?
    public private(set) var searchByFilterCallCount = 0
    public private(set) var lastSearchFilter: SearchFilter?
    public private(set) var fetchedMyLibraryFilters: [MyLibraryFilter] = []
    public private(set) var fetchedUserLibraryIDs: [UserID] = []
    public private(set) var fetchRegisteredNovelStatsCallCount = 0

    public init() {}

    public func fetchNovel(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        fetchedNovelIDs.append(id)
        return try fetchNovelResult.get()
    }

    public func addNovelInterest(id: NovelID) async throws(RepositoryError) {
        addedInterestIDs.append(id)
        try addInterestResult.get()
    }

    public func removeNovelInterest(id: NovelID) async throws(RepositoryError) {
        removedInterestIDs.append(id)
        try removeInterestResult.get()
    }

    public func searchNovelByText(_ text: String) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        searchByTextCallCount += 1
        lastSearchQuery = text
        return try searchByTextResult.get()
    }

    public func searchNovelByFilter(_ filter: SearchFilter) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        searchByFilterCallCount += 1
        lastSearchFilter = filter
        return try searchByFilterResult.get()
    }

    public func fetchMyLibraryNovels(_ filter: MyLibraryFilter) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int) {
        fetchedMyLibraryFilters.append(filter)
        return try fetchMyLibraryResult.get()
    }

    public func fetchUserLibraryNovels(id: UserID) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int) {
        fetchedUserLibraryIDs.append(id)
        return try fetchUserLibraryResult.get()
    }

    public func fetchRegisteredNovelStats() async throws(RepositoryError) -> RegisteredNovelStats {
        fetchRegisteredNovelStatsCallCount += 1
        return try fetchRegisteredNovelStatsResult.get()
    }
}
