//
//  DefaultFeedService.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct DefaultFeedService: FeedService {
    private let client: NetworkingRequestable

    init(client: NetworkingRequestable) {
        self.client = client
    }

    func postFeed(request: SubmitFeedRequest) async throws -> SubmitFeedResponse {
        let endpoint = FeedEndpoint.postFeed(request: request)
        return try await client.request(endpoint, decodeTo: SubmitFeedResponse.self)
    }

    func patchFeed(feedID: Int, request: SubmitFeedRequest) async throws -> SubmitFeedResponse {
        let endpoint = FeedEndpoint.patchFeed(feedID: feedID, request: request)
        return try await client.request(endpoint, decodeTo: SubmitFeedResponse.self)
    }

    func deleteFeed(feedID: Int) async throws {
        let endpoint = FeedEndpoint.deleteFeed(feedID: feedID)
        _ = try await client.request(endpoint)
    }

    func getFeedDetail(feedID: Int) async throws -> FeedDetailResponse {
        let endpoint = FeedEndpoint.getFeedDetail(feedID: feedID)
        return try await client.request(endpoint, decodeTo: FeedDetailResponse.self)
    }

    func getSosoFeeds(query: GetSosoFeedsQuery) async throws -> FeedListResponse {
        let endpoint = FeedEndpoint.getSosoFeeds(query: query)
        return try await client.request(endpoint, decodeTo: FeedListResponse.self)
    }

    func getUserFeeds(userID: Int, query: GetUserFeedsQuery) async throws -> UserFeedListResponse {
        let endpoint = FeedEndpoint.getUserFeeds(userID: userID, query: query)
        return try await client.request(endpoint, decodeTo: UserFeedListResponse.self)
    }

    func getMyFeeds(userID: Int, genres: [String], visibilityType: String, sortType: String, lastFeedID: Int) async throws -> UserFeedListResponse {
        let isVisible: Bool? = visibilityType == "PUBLIC" ? true : nil
        let isUnVisible: Bool? = visibilityType == "PRIVATE" ? true : nil
        let query = GetUserFeedsQuery(
            lastFeedId: lastFeedID,
            size: 20,
            isVisible: isVisible,
            isUnVisible: isUnVisible,
            genreNames: genres.isEmpty ? nil : genres,
            sortCriteria: sortType
        )
        let endpoint = FeedEndpoint.getMyFeeds(userID: userID, query: query)
        return try await client.request(endpoint, decodeTo: UserFeedListResponse.self)
    }

    func getNovelFeeds(novelID: Int, lastFeedID: Int, size: Int) async throws -> NovelFeedListResponse {
        let endpoint = FeedEndpoint.getNovelFeeds(novelID: novelID, lastFeedID: lastFeedID, size: size)
        return try await client.request(endpoint, decodeTo: NovelFeedListResponse.self)
    }

    func postLike(feedID: Int) async throws {
        let endpoint = FeedEndpoint.postLike(feedID: feedID)
        _ = try await client.request(endpoint)
    }

    func deleteLike(feedID: Int) async throws {
        let endpoint = FeedEndpoint.deleteLike(feedID: feedID)
        _ = try await client.request(endpoint)
    }
}
