//
//  MockCollectionRepository.swift
//  CollectionDomainTesting
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import CollectionDomain

public final class MockCollectionRepository: CollectionRepository {

    // MARK: - 주입할 결과

    public var fetchCollectionPreviewsResult: Result<([CollectionPreview], Int), RepositoryError>!
    public var fetchCollectionsResult: Result<(CursorPaginated<CollectionCard>, Int), RepositoryError>!
    public var fetchLikedCollectionsResult: Result<(CursorPaginated<CollectionCard>, Int), RepositoryError>!
    public var fetchCollectionDetailResult: Result<CollectionDetail, RepositoryError>!
    public var createCollectionResult: Result<CollectionID, RepositoryError>!
    public var updateCollectionResult: Result<Void, RepositoryError> = .success(())
    public var deleteCollectionResult: Result<Void, RepositoryError> = .success(())
    public var likeCollectionResult: Result<Void, RepositoryError> = .success(())
    public var unlikeCollectionResult: Result<Void, RepositoryError> = .success(())

    // MARK: - 호출 기록

    public private(set) var fetchedPreviewRequests: [(userID: UserID, size: Int)] = []
    public private(set) var fetchedCollectionRequests: [(userID: UserID, cursor: String?, size: Int)] = []
    public private(set) var fetchedLikedRequests: [(cursor: String?, size: Int)] = []
    public private(set) var fetchedDetailRequests: [(id: CollectionID, sortType: SortType)] = []
    public private(set) var createdDrafts: [CollectionDraft] = []
    public private(set) var updatedRequests: [(id: CollectionID, draft: CollectionDraft)] = []
    public private(set) var deletedIDs: [CollectionID] = []
    public private(set) var likedIDs: [CollectionID] = []
    public private(set) var unlikedIDs: [CollectionID] = []

    public init() {}

    // MARK: - CollectionRepository

    public func fetchCollectionPreviews(
        userID: UserID,
        size: Int
    ) async throws(RepositoryError) -> ([CollectionPreview], Int) {
        fetchedPreviewRequests.append((userID, size))
        return try fetchCollectionPreviewsResult.get()
    }

    public func fetchCollections(
        userID: UserID,
        cursor: String?,
        size: Int
    ) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        fetchedCollectionRequests.append((userID, cursor, size))
        return try fetchCollectionsResult.get()
    }

    public func fetchLikedCollections(
        cursor: String?,
        size: Int
    ) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        fetchedLikedRequests.append((cursor, size))
        return try fetchLikedCollectionsResult.get()
    }

    public func fetchCollectionDetail(
        id: CollectionID,
        sortType: SortType
    ) async throws(RepositoryError) -> CollectionDetail {
        fetchedDetailRequests.append((id, sortType))
        return try fetchCollectionDetailResult.get()
    }

    public func createCollection(_ draft: CollectionDraft) async throws(RepositoryError) -> CollectionID {
        createdDrafts.append(draft)
        return try createCollectionResult.get()
    }

    public func updateCollection(id: CollectionID, draft: CollectionDraft) async throws(RepositoryError) {
        updatedRequests.append((id, draft))
        try updateCollectionResult.get()
    }

    public func deleteCollection(id: CollectionID) async throws(RepositoryError) {
        deletedIDs.append(id)
        try deleteCollectionResult.get()
    }

    public func likeCollection(id: CollectionID) async throws(RepositoryError) {
        likedIDs.append(id)
        try likeCollectionResult.get()
    }

    public func unlikeCollection(id: CollectionID) async throws(RepositoryError) {
        unlikedIDs.append(id)
        try unlikeCollectionResult.get()
    }
}
