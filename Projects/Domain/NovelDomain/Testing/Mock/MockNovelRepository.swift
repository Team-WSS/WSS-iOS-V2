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
    public var fetchMyLibraryResult: Result<(CursorPaginated<LibraryNovel>, Int), RepositoryError>!
    public var fetchUserLibraryResult: Result<(Paginated<LibraryNovel>, Int), RepositoryError>!
    public var fetchMyLibraryKeywordsResult: Result<[Keyword], RepositoryError>!
    public var fetchRegisteredNovelStatsResult: Result<RegisteredNovelStats, RepositoryError>!

    public private(set) var fetchedNovelIDs: [NovelID] = []
    public private(set) var lastCachedKeywords: [Keyword]?
    public private(set) var addedInterestIDs: [NovelID] = []
    public private(set) var removedInterestIDs: [NovelID] = []
    public private(set) var fetchedMyLibraryFilters: [MyLibraryFilter] = []
    public private(set) var fetchedMyLibraryCursors: [String?] = []
    public private(set) var lastMyLibraryCachedKeywords: [Keyword]?
    public private(set) var fetchedUserLibraryIDs: [UserID] = []
    public private(set) var fetchedUserLibraryFilters: [LibraryFilter] = []
    public private(set) var fetchMyLibraryKeywordsCallCount = 0
    public private(set) var fetchRegisteredNovelStatsCallCount = 0

    public init() {}

    public func fetchNovel(id: NovelID, cachedKeywords: [Keyword]) async throws(RepositoryError) -> NovelInformation {
        fetchedNovelIDs.append(id)
        lastCachedKeywords = cachedKeywords
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

    public func fetchMyLibraryNovels(
        _ filter: MyLibraryFilter,
        cursor: String?,
        cachedKeywords: [Keyword]
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        fetchedMyLibraryFilters.append(filter)
        fetchedMyLibraryCursors.append(cursor)
        lastMyLibraryCachedKeywords = cachedKeywords
        return try fetchMyLibraryResult.get()
    }

    public func fetchMyLibraryKeywords() async throws(RepositoryError) -> [Keyword] {
        fetchMyLibraryKeywordsCallCount += 1
        return try fetchMyLibraryKeywordsResult.get()
    }

    public func fetchUserLibraryNovels(id: UserID, _ filter: LibraryFilter) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int) {
        fetchedUserLibraryIDs.append(id)
        fetchedUserLibraryFilters.append(filter)
        return try fetchUserLibraryResult.get()
    }

    public func fetchRegisteredNovelStats() async throws(RepositoryError) -> RegisteredNovelStats {
        fetchRegisteredNovelStatsCallCount += 1
        return try fetchRegisteredNovelStatsResult.get()
    }
}
