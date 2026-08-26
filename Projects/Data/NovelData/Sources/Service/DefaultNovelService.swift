//
//  DefaultNovelService.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct DefaultNovelService: NovelService {
    private let client: NetworkingRequestable

    public init(client: NetworkingRequestable) {
        self.client = client
    }

    public func getUserLibraryNovels(userID: Int,
                              query: UserLibraryQuery) async throws -> UserLibraryNovelsResponse {
        let endpoint = NovelEndpoint.getUserLibraryNovels(userID: userID, query)
        return try await client.request(endpoint, decodeTo: UserLibraryNovelsResponse.self)
    }

    public func getUserLibraryNovelsV2(userID: Int,
                                       query: UserLibraryV2Query) async throws -> UserLibraryNovelsV2Response {
        let endpoint = NovelEndpoint.getUserLibraryNovelsV2(userID: userID, query)
        return try await client.request(endpoint, decodeTo: UserLibraryNovelsV2Response.self)
    }

    public func getUserLibraryKeywords(userID: Int) async throws -> LibraryKeywordsResponse {
        let endpoint = NovelEndpoint.getUserLibraryKeywords(userID: userID)
        return try await client.request(endpoint, decodeTo: LibraryKeywordsResponse.self)
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
}
