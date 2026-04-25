//
//  MockSocialService.swift
//  SocialDataTesting
//
//  Created by YunhakLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
@testable import SocialData

final class MockSocialService: SocialService {

    // MARK: - Call tracking

    private(set) var postBlockUserCallCount = 0
    private(set) var blockedUserIDs: [Int] = []
    private(set) var deleteBlockCallCount = 0
    private(set) var deletedBlockIDs: [Int] = []
    private(set) var getBlockedUsersCallCount = 0
    private(set) var postReportSpoilerFeedCallCount = 0
    private(set) var reportedSpoilerFeedIDs: [Int] = []
    private(set) var postReportImproperFeedCallCount = 0
    private(set) var reportedImproperFeedIDs: [Int] = []
    private(set) var postReportSpoilerCommentCallCount = 0
    private(set) var reportedSpoilerCommentIDs: [Int] = []
    private(set) var postReportImproperCommentCallCount = 0
    private(set) var reportedImproperCommentIDs: [Int] = []

    // MARK: - Results

    var postBlockUserResult: Result<Void, Error> = .success(())
    var deleteBlockResult: Result<Void, Error> = .success(())
    var getBlockedUsersResult: Result<[BlockedUserResponse], Error> = .success([])
    var postReportSpoilerFeedResult: Result<Void, Error> = .success(())
    var postReportImproperFeedResult: Result<Void, Error> = .success(())
    var postReportSpoilerCommentResult: Result<Void, Error> = .success(())
    var postReportImproperCommentResult: Result<Void, Error> = .success(())

    // MARK: - SocialService

    func postBlockUser(userID: Int) async throws {
        postBlockUserCallCount += 1
        blockedUserIDs.append(userID)
        try postBlockUserResult.get()
    }

    func deleteBlock(blockID: Int) async throws {
        deleteBlockCallCount += 1
        deletedBlockIDs.append(blockID)
        try deleteBlockResult.get()
    }

    func getBlockedUsers() async throws -> [BlockedUserResponse] {
        getBlockedUsersCallCount += 1
        return try getBlockedUsersResult.get()
    }

    func postReportSpoilerFeed(feedID: Int) async throws {
        postReportSpoilerFeedCallCount += 1
        reportedSpoilerFeedIDs.append(feedID)
        try postReportSpoilerFeedResult.get()
    }

    func postReportImproperFeed(feedID: Int) async throws {
        postReportImproperFeedCallCount += 1
        reportedImproperFeedIDs.append(feedID)
        try postReportImproperFeedResult.get()
    }

    func postReportSpoilerComment(commentID: Int) async throws {
        postReportSpoilerCommentCallCount += 1
        reportedSpoilerCommentIDs.append(commentID)
        try postReportSpoilerCommentResult.get()
    }

    func postReportImproperComment(commentID: Int) async throws {
        postReportImproperCommentCallCount += 1
        reportedImproperCommentIDs.append(commentID)
        try postReportImproperCommentResult.get()
    }
}
