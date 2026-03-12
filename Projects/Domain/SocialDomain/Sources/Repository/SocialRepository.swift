//
//  SocialRepository.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol SocialRepository {
    
    // MARK: - Block
    
    func blockUser(id: UserID) async throws(RepositoryError)
    func unblockUser(id: BlockID) async throws(RepositoryError)
    func loadBlockedUsers() async throws(RepositoryError) -> [BlockedUser]
    
    // MARK: - Report
    
    func reportSpoilerFeed(id: FeedID) async throws(RepositoryError)
    func reportImproperFeed(id: FeedID) async throws(RepositoryError)
    func reportSpoilerComment(id: CommentID) async throws(RepositoryError)
    func reportImproperComment(id: CommentID) async throws(RepositoryError)
}
