//
//  MockFeedService.swift
//  FeedDataTesting
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
@testable import FeedData

final class MockFeedService: FeedService {

    // MARK: - Call tracking

    private(set) var postFeedCallCount = 0
    private(set) var postedRequests: [SubmitFeedRequest] = []

    private(set) var patchFeedCallCount = 0
    private(set) var patchedFeedIDs: [Int] = []
    private(set) var patchedRequests: [SubmitFeedRequest] = []

    private(set) var deleteFeedCallCount = 0
    private(set) var deletedFeedIDs: [Int] = []

    private(set) var getFeedDetailCallCount = 0
    private(set) var fetchedDetailFeedIDs: [Int] = []

    private(set) var getSosoFeedsCallCount = 0
    private(set) var fetchedSosoOptions: [String] = []
    private(set) var fetchedSosoLastFeedIDs: [Int] = []

    private(set) var getUserFeedsCallCount = 0
    private(set) var fetchedUserIDs: [Int] = []
    private(set) var fetchedUserLastFeedIDs: [Int] = []

    private(set) var getMyFeedsCallCount = 0
    private(set) var fetchedMyGenres: [[String]] = []
    private(set) var fetchedMyVisibilityTypes: [String] = []
    private(set) var fetchedMySortTypes: [String] = []

    private(set) var getNovelFeedsCallCount = 0
    private(set) var fetchedNovelIDs: [Int] = []
    private(set) var fetchedNovelLastFeedIDs: [Int] = []

    private(set) var postLikeCallCount = 0
    private(set) var likedFeedIDs: [Int] = []

    private(set) var deleteLikeCallCount = 0
    private(set) var unlikedFeedIDs: [Int] = []

    // MARK: - Results

    var postFeedResult: Result<Void, Error> = .success(())
    var patchFeedResult: Result<Void, Error> = .success(())
    var deleteFeedResult: Result<Void, Error> = .success(())
    var getFeedDetailResult: Result<FeedDetailResponse, Error>!
    var getSosoFeedsResult: Result<FeedListResponse, Error>!
    var getUserFeedsResult: Result<FeedListResponse, Error>!
    var getMyFeedsResult: Result<FeedListResponse, Error>!
    var getNovelFeedsResult: Result<FeedListResponse, Error>!
    var postLikeResult: Result<Void, Error> = .success(())
    var deleteLikeResult: Result<Void, Error> = .success(())

    // MARK: - FeedService

    func postFeed(request: SubmitFeedRequest) async throws {
        postFeedCallCount += 1
        postedRequests.append(request)
        try postFeedResult.get()
    }

    func patchFeed(feedID: Int, request: SubmitFeedRequest) async throws {
        patchFeedCallCount += 1
        patchedFeedIDs.append(feedID)
        patchedRequests.append(request)
        try patchFeedResult.get()
    }

    func deleteFeed(feedID: Int) async throws {
        deleteFeedCallCount += 1
        deletedFeedIDs.append(feedID)
        try deleteFeedResult.get()
    }

    func getFeedDetail(feedID: Int) async throws -> FeedDetailResponse {
        getFeedDetailCallCount += 1
        fetchedDetailFeedIDs.append(feedID)
        return try getFeedDetailResult.get()
    }

    func getSosoFeeds(option: String, lastFeedID: Int) async throws -> FeedListResponse {
        getSosoFeedsCallCount += 1
        fetchedSosoOptions.append(option)
        fetchedSosoLastFeedIDs.append(lastFeedID)
        return try getSosoFeedsResult.get()
    }

    func getUserFeeds(userID: Int, lastFeedID: Int) async throws -> FeedListResponse {
        getUserFeedsCallCount += 1
        fetchedUserIDs.append(userID)
        fetchedUserLastFeedIDs.append(lastFeedID)
        return try getUserFeedsResult.get()
    }

    func getMyFeeds(genres: [String], visibilityType: String, sortType: String, lastFeedID: Int) async throws -> FeedListResponse {
        getMyFeedsCallCount += 1
        fetchedMyGenres.append(genres)
        fetchedMyVisibilityTypes.append(visibilityType)
        fetchedMySortTypes.append(sortType)
        return try getMyFeedsResult.get()
    }

    func getNovelFeeds(novelID: Int, lastFeedID: Int) async throws -> FeedListResponse {
        getNovelFeedsCallCount += 1
        fetchedNovelIDs.append(novelID)
        fetchedNovelLastFeedIDs.append(lastFeedID)
        return try getNovelFeedsResult.get()
    }

    func postLike(feedID: Int) async throws {
        postLikeCallCount += 1
        likedFeedIDs.append(feedID)
        try postLikeResult.get()
    }

    func deleteLike(feedID: Int) async throws {
        deleteLikeCallCount += 1
        unlikedFeedIDs.append(feedID)
        try deleteLikeResult.get()
    }
}
