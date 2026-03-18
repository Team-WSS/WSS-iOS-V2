//
//  MockSocialRepository.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import SocialDomain
import BaseDomain

public final class MockSocialRepository: SocialRepository {
    
    public init() { }

    // MARK: - Block

    public var loadBlockedUsersCallCount = 0
    public var loadBlockedUsersResult: Result<[BlockedUser], RepositoryError> = .success([])

    public func loadBlockedUsers() async throws(RepositoryError) -> [BlockedUser] {
        loadBlockedUsersCallCount += 1
        return try loadBlockedUsersResult.get()
    }

    public var blockUserCallCount = 0
    public var blockedUserIDs: [UserID] = []
    public var blockUserResult: Result<Void, RepositoryError> = .success(())

    public func blockUser(id: UserID) async throws(RepositoryError) {
        blockUserCallCount += 1
        blockedUserIDs.append(id)
        _ = try blockUserResult.get()
    }

    public var unblockUserCallCount = 0
    public var unblockedBlockIDs: [BlockID] = []
    public var unblockUserResult: Result<Void, RepositoryError> = .success(())

    public func unblockUser(id: BlockID) async throws(RepositoryError) {
        unblockUserCallCount += 1
        unblockedBlockIDs.append(id)
        _ = try unblockUserResult.get()
    }

    // MARK: - Report feed

    public var reportSpoilerFeedCallCount = 0
    public var reportedSpoilerFeedIDs: [FeedID] = []
    public var reportSpoilerFeedResult: Result<Void, RepositoryError> = .success(())

    public func reportSpoilerFeed(id: FeedID) async throws(RepositoryError) {
        reportSpoilerFeedCallCount += 1
        reportedSpoilerFeedIDs.append(id)
        _ = try reportSpoilerFeedResult.get()
    }

    public var reportImproperFeedCallCount = 0
    public var reportedImproperFeedIDs: [FeedID] = []
    public var reportImproperFeedResult: Result<Void, RepositoryError> = .success(())

    public func reportImproperFeed(id: FeedID) async throws(RepositoryError) {
        reportImproperFeedCallCount += 1
        reportedImproperFeedIDs.append(id)
        _ = try reportImproperFeedResult.get()
    }

    // MARK: - Report comment

    public var reportSpoilerCommentCallCount = 0
    public var reportedSpoilerCommentIDs: [CommentID] = []
    public var reportSpoilerCommentResult: Result<Void, RepositoryError> = .success(())

    public func reportSpoilerComment(id: CommentID) async throws(RepositoryError) {
        reportSpoilerCommentCallCount += 1
        reportedSpoilerCommentIDs.append(id)
        _ = try reportSpoilerCommentResult.get()
    }

    public var reportImproperCommentCallCount = 0
    public var reportedImproperCommentIDs: [CommentID] = []
    public var reportImproperCommentResult: Result<Void, RepositoryError> = .success(())

    public func reportImproperComment(id: CommentID) async throws(RepositoryError) {
        reportImproperCommentCallCount += 1
        reportedImproperCommentIDs.append(id)
        _ = try reportImproperCommentResult.get()
    }
}
