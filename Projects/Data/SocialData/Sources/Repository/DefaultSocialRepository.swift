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
        let action = SocialAction.blockUser
        
        do {
            let query = BlockUserQuery(userID: id.value)
            try await service.postBlockUser(query)
            logger.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func unblockUser(id: BlockID) async throws(RepositoryError) {
        let action = SocialAction.unblockUser
        
        do {
            try await service.deleteBlock(blockID: id.value)
            logger.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func loadBlockedUsers() async throws(RepositoryError) -> [BlockedUser] {
        let action = SocialAction.loadBlockedUsers
        
        do {
            let responses = try await service.getBlockedUsers()
            logger.logSuccess(action: action.name)
            return SocialMapper.blockedUsers(from: responses)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func reportSpoilerFeed(id: FeedID) async throws(RepositoryError) {
        let action = SocialAction.reportSpoilerFeed
        
        do {
            try await service.postReportSpoilerFeed(feedID: id.value)
            logger.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func reportImproperFeed(id: FeedID) async throws(RepositoryError) {
        let action = SocialAction.reportImproperFeed
        
        do {
            try await service.postReportImproperFeed(feedID: id.value)
            logger.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func reportSpoilerComment(feedID: FeedID, commentID: CommentID) async throws(RepositoryError) {
        let action = SocialAction.reportSpoilerComment
        
        do {
            try await service.postReportSpoilerComment(feedID: feedID.value, commentID: commentID.value)
            logger.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func reportImproperComment(feedID: FeedID, commentID: CommentID) async throws(RepositoryError) {
        let action = SocialAction.reportImproperComment
        
        do {
            try await service.postReportImproperComment(feedID: feedID.value, commentID: commentID.value)
            logger.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
}
