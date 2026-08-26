//
//  CollectionService.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

protocol CollectionService {
    func getUserCollections(userID: Int, query: CollectionsQuery) async throws -> CollectionsResponse
    func getLikedCollections(query: CollectionsQuery) async throws -> CollectionsResponse
    func getCollectionDetail(collectionID: Int, query: CollectionDetailQuery) async throws -> CollectionDetailResponse
    func postCollection(request: SubmitCollectionRequest) async throws -> CreateCollectionResponse
    func putCollection(collectionID: Int, request: SubmitCollectionRequest) async throws
    func deleteCollection(collectionID: Int) async throws
    func putCollectionLike(collectionID: Int) async throws
    func deleteCollectionLike(collectionID: Int) async throws
}
