//
//  DefaultCollectionRepository.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import CollectionDomain
import BaseDomain
import Networking
import BaseData

struct DefaultCollectionRepository: CollectionRepository {

    private let service: CollectionService
    private let logger: DataLogger?

    init(
        service: CollectionService,
        logger: DataLogger?
    ) {
        self.service = service
        self.logger = logger
    }

    // MARK: - 목록

    public func fetchCollectionPreviews(
        userID: UserID,
        size: Int
    ) async throws(RepositoryError) -> ([CollectionPreview], Int) {
        let action = CollectionAction.fetchCollectionPreviews(userID: userID.value)

        do {
            let response = try await service.getUserCollections(
                userID: userID.value,
                query: CollectionsQuery(cursor: nil, size: size)
            )
            let result = CollectionMapper.collectionPreviews(from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchCollections(
        userID: UserID,
        cursor: String?,
        size: Int
    ) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        let action = CollectionAction.fetchCollections(userID: userID.value)

        do {
            let response = try await service.getUserCollections(
                userID: userID.value,
                query: CollectionsQuery(cursor: cursor, size: size)
            )
            let result = CollectionMapper.collectionCards(from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchLikedCollections(
        cursor: String?,
        size: Int
    ) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        let action = CollectionAction.fetchLikedCollections

        do {
            let response = try await service.getLikedCollections(
                query: CollectionsQuery(cursor: cursor, size: size)
            )
            let result = CollectionMapper.collectionCards(from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    // MARK: - 상세

    public func fetchCollectionDetail(
        id: CollectionID,
        sortType: SortType
    ) async throws(RepositoryError) -> CollectionDetail {
        let action = CollectionAction.fetchCollectionDetail(collectionID: id.value)

        do {
            let response = try await service.getCollectionDetail(
                collectionID: id.value,
                query: CollectionDetailQuery(sortType: sortType)
            )
            let result = CollectionMapper.collectionDetail(from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    // MARK: - 생성·수정·삭제

    public func createCollection(_ draft: CollectionDraft) async throws(RepositoryError) -> CollectionID {
        let action = CollectionAction.createCollection

        do {
            let request = try CollectionMapper.submitRequest(from: draft)
            let response = try await service.postCollection(request: request)
            logger?.logSuccess(action: action.name)
            return CollectionID(response.collectionId)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func updateCollection(id: CollectionID, draft: CollectionDraft) async throws(RepositoryError) {
        let action = CollectionAction.updateCollection(collectionID: id.value)

        do {
            let request = try CollectionMapper.submitRequest(from: draft)
            try await service.putCollection(collectionID: id.value, request: request)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func deleteCollection(id: CollectionID) async throws(RepositoryError) {
        let action = CollectionAction.deleteCollection(collectionID: id.value)

        do {
            try await service.deleteCollection(collectionID: id.value)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    // MARK: - 좋아요

    public func likeCollection(id: CollectionID) async throws(RepositoryError) {
        let action = CollectionAction.likeCollection(collectionID: id.value)

        do {
            try await service.putCollectionLike(collectionID: id.value)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func unlikeCollection(id: CollectionID) async throws(RepositoryError) {
        let action = CollectionAction.unlikeCollection(collectionID: id.value)

        do {
            try await service.deleteCollectionLike(collectionID: id.value)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
}
