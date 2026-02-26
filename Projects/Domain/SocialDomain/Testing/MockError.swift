//
//  MockError.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  MockSocialRepository.swift
//  SocialDomainTests
//

import Foundation
@testable import SocialDomain
import BaseDomain

final class MockSocialRepository: SocialRepository {

    // MARK: - Block

    var loadBlockedUsersCallCount = 0
    var loadBlockedUsersResult: Result<[BlockedUser], RepositoryError> = .success([])

    func loadBlockedUsers() async throws(RepositoryError) -> [BlockedUser] {
        loadBlockedUsersCallCount += 1
        return try loadBlockedUsersResult.get()
    }

    var blockUserCallCount = 0
    var blockedUserIDs: [UserID] = []
    var blockUserResult: Result<Void, RepositoryError> = .success(())

    func blockUser(id: UserID) async throws(RepositoryError) {
        blockUserCallCount += 1
        blockedUserIDs.append(id)
        _ = try blockUserResult.get()
    }

    var unblockUserCallCount = 0
    var unblockedBlockIDs: [BlockID] = []
    var unblockUserResult: Result<Void, RepositoryError> = .success(())

    func unblockUser(id: BlockID) async throws(RepositoryError) {
        unblockUserCallCount += 1
        unblockedBlockIDs.append(id)
        _ = try unblockUserResult.get()
    }

    // MARK: - Report feed

    var reportSpoilerFeedCallCount = 0
    var reportedSpoilerFeedIDs: [FeedID] = []
    var reportSpoilerFeedResult: Result<Void, RepositoryError> = .success(())

    func reportSpoilerFeed(id: FeedID) async throws(RepositoryError) {
        reportSpoilerFeedCallCount += 1
        reportedSpoilerFeedIDs.append(id)
        _ = try reportSpoilerFeedResult.get()
    }

    var reportImproperFeedCallCount = 0
    var reportedImproperFeedIDs: [FeedID] = []
    var reportImproperFeedResult: Result<Void, RepositoryError> = .success(())

    func reportImproperFeed(id: FeedID) async throws(RepositoryError) {
        reportImproperFeedCallCount += 1
        reportedImproperFeedIDs.append(id)
        _ = try reportImproperFeedResult.get()
    }

    // MARK: - Report comment

    var reportSpoilerCommentCallCount = 0
    var reportedSpoilerCommentIDs: [CommentID] = []
    var reportSpoilerCommentResult: Result<Void, RepositoryError> = .success(())

    func reportSpoilerComment(id: CommentID) async throws(RepositoryError) {
        reportSpoilerCommentCallCount += 1
        reportedSpoilerCommentIDs.append(id)
        _ = try reportSpoilerCommentResult.get()
    }

    var reportImproperCommentCallCount = 0
    var reportedImproperCommentIDs: [CommentID] = []
    var reportImproperCommentResult: Result<Void, RepositoryError> = .success(())

    func reportImproperComment(id: CommentID) async throws(RepositoryError) {
        reportImproperCommentCallCount += 1
        reportedImproperCommentIDs.append(id)
        _ = try reportImproperCommentResult.get()
    }
}
