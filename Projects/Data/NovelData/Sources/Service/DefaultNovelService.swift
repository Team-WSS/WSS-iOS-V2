//
//  DefaultNovelService.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

public struct DefaultNovelService: NovelService {
    private let client: NetworkingRequestable

    public init(client: NetworkingRequestable) {
        self.client = client
    }

    public func getUserLibraryNovels(userID: Int,
                              query: UserLibraryQuery) async throws -> UserLibraryNovelsResponse {
        let endpoint = NovelEndpoint.getUserLibraryNovels(userID: userID, query)
        return try await client.request(endpoint, decodeTo: UserLibraryNovelsResponse.self)
    }

    public func getNovelBasicInfo(novelID: Int) async throws -> NovelBasicResponse {
        let endpoint = NovelEndpoint.getNovelBasicInfo(novelID: novelID)
        return try await client.request(endpoint, decodeTo: NovelBasicResponse.self)
    }

    public func getNovelDetailInfo(novelID: Int) async throws -> NovelInfoResponse {
        let endpoint = NovelEndpoint.getNovelDetailInfo(novelID: novelID)
        return try await client.request(endpoint, decodeTo: NovelInfoResponse.self)
    }

    public func getUserRegisteredNovelStats(userID: Int) async throws -> UserRegisteredNovelStatesResponse {
        let endpoint = NovelEndpoint.getRegisteredNovelStats(userID: userID)
        return try await client.request(endpoint, decodeTo: UserRegisteredNovelStatesResponse.self)
    }

    public func postNovelInterest(novelID: Int) async throws {
        let endpoint = NovelEndpoint.postNovelInterest(novelID: novelID)
        _ = try await client.request(endpoint)
    }

    public func deleteNovelInterest(novelID: Int) async throws {
        let endpoint = NovelEndpoint.deleteNovelInterest(novelID: novelID)
        _ = try await client.request(endpoint)
    }

    public func getNormalSearchNovels(query: NormalSearchQuery) async throws -> SearchNovelsResponse {
        let endpoint = NovelEndpoint.getNormalSearchResult(query)
        return try await client.request(endpoint, decodeTo: SearchNovelsResponse.self)
    }

    public func getDetailSearchNovels(query: DetailSearchQuery) async throws -> SearchNovelsResponse {
        let endpoint = NovelEndpoint.getDetailSearchResult(query)
        return try await client.request(endpoint, decodeTo: SearchNovelsResponse.self)
    }
}
