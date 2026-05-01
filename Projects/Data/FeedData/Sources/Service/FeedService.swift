//
//  FeedService.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

protocol FeedService {
    func postFeed(request: SubmitFeedRequest) async throws -> SubmitFeedResponse
    func patchFeed(feedID: Int, request: SubmitFeedRequest) async throws -> SubmitFeedResponse
    func deleteFeed(feedID: Int) async throws
    func getFeedDetail(feedID: Int) async throws -> FeedDetailResponse
    func getSosoFeeds(query: GetSosoFeedsQuery) async throws -> FeedListResponse
    func getUserFeeds(userID: Int, query: GetUserFeedsQuery) async throws -> UserFeedListResponse
    func getMyFeeds(genres: [String], visibilityType: String, sortType: String, lastFeedID: Int) async throws -> FeedListResponse
    func getNovelFeeds(novelID: Int, lastFeedID: Int, size: Int) async throws -> NovelFeedListResponse
    func postLike(feedID: Int) async throws
    func deleteLike(feedID: Int) async throws
}
