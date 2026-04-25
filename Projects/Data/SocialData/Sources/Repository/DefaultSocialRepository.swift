//
//  DefaultSocialRepository.swift
//  SocialData
//
//  Created by YunhakLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SocialDomain
import BaseDomain
import BaseData
import Networking

public struct DefaultSocialRepository: SocialRepository {
    private let service: SocialService
    private let logger: DataLogger

    init(
        service: SocialService,
        logger: DataLogger
    ) {
        self.service = service
        self.logger = logger
    }

    public func blockUser(id: UserID) async throws(RepositoryError) {
        do {
            try await service.postBlockUser(userID: id.value)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "blockUser", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "blockUser", error: error)
            throw .unknown
        }
    }

    public func unblockUser(id: BlockID) async throws(RepositoryError) {
        do {
            try await service.deleteBlock(blockID: id.value)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "unblockUser", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "unblockUser", error: error)
            throw .unknown
        }
    }

    public func loadBlockedUsers() async throws(RepositoryError) -> [BlockedUser] {
        do {
            let responses = try await service.getBlockedUsers()
            return SocialMapper.blockedUsers(from: responses)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "loadBlockedUsers", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "loadBlockedUsers", error: error)
            throw .unknown
        }
    }

    public func reportSpoilerFeed(id: FeedID) async throws(RepositoryError) {
        do {
            try await service.postReportSpoilerFeed(feedID: id.value)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "reportSpoilerFeed", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "reportSpoilerFeed", error: error)
            throw .unknown
        }
    }

    public func reportImproperFeed(id: FeedID) async throws(RepositoryError) {
        do {
            try await service.postReportImproperFeed(feedID: id.value)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "reportImproperFeed", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "reportImproperFeed", error: error)
            throw .unknown
        }
    }

    public func reportSpoilerComment(feedID: FeedID, commentID: CommentID) async throws(RepositoryError) {
        do {
            try await service.postReportSpoilerComment(feedID: feedID.value, commentID: commentID.value)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "reportSpoilerComment", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "reportSpoilerComment", error: error)
            throw .unknown
        }
    }

    public func reportImproperComment(feedID: FeedID, commentID: CommentID) async throws(RepositoryError) {
        do {
            try await service.postReportImproperComment(feedID: feedID.value, commentID: commentID.value)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "reportImproperComment", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "reportImproperComment", error: error)
            throw .unknown
        }
    }
}
