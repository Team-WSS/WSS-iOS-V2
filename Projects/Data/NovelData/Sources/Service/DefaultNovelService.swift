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
    
    init(client: NetworkingRequestable) {
        self.client = client
    }
    
    func getUserLibraryNovels(userID: Int,
                              query: UserLibraryQuery) async throws -> UserLibraryNovelsResponse {
        let endpoint = NovelEndpoint.getUserLibraryNovels(userID: userID, query)
        return try await client.request(endpoint, decodeTo: UserLibraryNovelsResponse.self)
    }
    
    func getNovelBasicInfo(novelID: Int) async throws -> NovelBasicResponse {
        let endpoint = NovelEndpoint.getNovelBasicInfo(novelID: novelID)
        return try await client.request(endpoint, decodeTo: NovelBasicResponse.self)
    }
    
    func getNovelDetailInfo(novelID: Int) async throws -> NovelInfoResponse {
        let endpoint = NovelEndpoint.getNovelDetailInfo(novelID: novelID)
        return try await client.request(endpoint, decodeTo: NovelInfoResponse.self)
    }
    
    func getUserRegisteredNovelStats(userID: Int) async throws -> UserRegisteredNovelStatesResponse {
        let endpoint = NovelEndpoint.getRegisteredNovelStats(userID: userID)
        return try await client.request(endpoint, decodeTo: UserRegisteredNovelStatesResponse.self)
    }
    
    func postNovelInterest(novelID: Int) async throws {
        let endpoint = NovelEndpoint.postNovelInterest(novelID: novelID)
        _ = try await client.request(endpoint)
    }
    
    func deleteNovelInterest(novelID: Int) async throws {
        let endpoint = NovelEndpoint.postNovelInterest(novelID: novelID)
        _ = try await client.request(endpoint)
    }
    
    func getNormalSearchNovels(query: NormalSearchQuery) async throws -> SearchNovelsResponse {
        let endpoint = NovelEndpoint.getNormalSearchResult(query)
        return try await client.request(endpoint, decodeTo: SearchNovelsResponse.self)
    }
    
    func getDetailSearchNovels(query: DetailSearchQuery) async throws -> SearchNovelsResponse {
        let endpoint = NovelEndpoint.getDetailSearchResult(query)
        return try await client.request(endpoint, decodeTo: SearchNovelsResponse.self)
    }
}
