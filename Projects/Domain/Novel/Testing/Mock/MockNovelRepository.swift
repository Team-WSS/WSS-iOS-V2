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

    public var fetchNovelResult: Result<NovelInformation, Error>!
    public var addInterestResult: Result<Void, Error> = .success(())
    public var removeInterestResult: Result<Void, Error> = .success(())
    public var searchByTextResult: Result<(Paginated<Novel>, Int), Error>!
    public var searchByFilterResult: Result<(Paginated<Novel>, Int), Error>!
    public var fetchMyLibraryResult: Result<(Paginated<LibraryNovel>, Int), Error>!
    public var fetchUserLibraryResult: Result<(Paginated<LibraryNovel>, Int), Error>!

    public private(set) var fetchedNovelIDs: [NovelID] = []
    public private(set) var addedInterestIDs: [NovelID] = []
    public private(set) var removedInterestIDs: [NovelID] = []
    public private(set) var searchByTextCallCount = 0
    public private(set) var lastSearchQuery: String?
    public private(set) var searchByFilterCallCount = 0
    public private(set) var lastSearchFilter: SearchFilter?
    public private(set) var fetchedMyLibraryFilters: [MyLibraryFilter] = []
    public private(set) var fetchedUserLibraryIDs: [UserID] = []

    public init() {}

    public func fetchNovel(id: NovelID) async throws -> NovelInformation {
        fetchedNovelIDs.append(id)
        return try fetchNovelResult.get()
    }

    public func addNovelInterest(id: NovelID) async throws {
        addedInterestIDs.append(id)
        try addInterestResult.get()
    }

    public func removeNovelInterest(id: NovelID) async throws {
        removedInterestIDs.append(id)
        try removeInterestResult.get()
    }

    public func searchNovelByText(_ text: String) async throws -> (Paginated<Novel>, Int) {
        searchByTextCallCount += 1
        lastSearchQuery = text
        return try searchByTextResult.get()
    }

    public func searchNovelByFilter(_ filter: SearchFilter) async throws -> (Paginated<Novel>, Int) {
        searchByFilterCallCount += 1
        lastSearchFilter = filter
        return try searchByFilterResult.get()
    }

    public func fetchMyLibraryNovels(_ filter: MyLibraryFilter) async throws -> (Paginated<LibraryNovel>, Int) {
        fetchedMyLibraryFilters.append(filter)
        return try fetchMyLibraryResult.get()
    }

    public func fetchUserLibraryNovels(id: UserID) async throws -> (Paginated<LibraryNovel>, Int) {
        fetchedUserLibraryIDs.append(id)
        return try fetchUserLibraryResult.get()
    }
}
