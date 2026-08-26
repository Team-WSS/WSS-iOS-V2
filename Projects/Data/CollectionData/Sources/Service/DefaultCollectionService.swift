//
//  DefaultCollectionService.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import Networking

struct DefaultCollectionService: CollectionService {

    private let network: NetworkingRequestable

    init(network: NetworkingRequestable) {
        self.network = network
    }

    public func getUserCollections(userID: Int, query: CollectionsQuery) async throws -> CollectionsResponse {
        try await network.request(
            CollectionEndpoint.getUserCollections(userID: userID, query),
            decodeTo: CollectionsResponse.self
        )
    }

    public func getLikedCollections(query: CollectionsQuery) async throws -> CollectionsResponse {
        try await network.request(
            CollectionEndpoint.getLikedCollections(query),
            decodeTo: CollectionsResponse.self
        )
    }

    public func getCollectionDetail(
        collectionID: Int,
        query: CollectionDetailQuery
    ) async throws -> CollectionDetailResponse {
        try await network.request(
            CollectionEndpoint.getCollectionDetail(collectionID: collectionID, query),
            decodeTo: CollectionDetailResponse.self
        )
    }

    public func postCollection(request: SubmitCollectionRequest) async throws -> CreateCollectionResponse {
        try await network.request(
            CollectionEndpoint.postCollection(request),
            decodeTo: CreateCollectionResponse.self
        )
    }

    public func putCollection(collectionID: Int, request: SubmitCollectionRequest) async throws {
        _ = try await network.request(CollectionEndpoint.putCollection(collectionID: collectionID, request))
    }

    public func deleteCollection(collectionID: Int) async throws {
        _ = try await network.request(CollectionEndpoint.deleteCollection(collectionID: collectionID))
    }

    public func putCollectionLike(collectionID: Int) async throws {
        _ = try await network.request(CollectionEndpoint.putCollectionLike(collectionID: collectionID))
    }

    public func deleteCollectionLike(collectionID: Int) async throws {
        _ = try await network.request(CollectionEndpoint.deleteCollectionLike(collectionID: collectionID))
    }
}
