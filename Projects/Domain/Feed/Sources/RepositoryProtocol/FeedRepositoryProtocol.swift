//
//  FeedRepositoryProtocol.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol FeedRepositoryProtocol {
    func submitFeed(_ draft: FeedDraftEntity) async throws
    func editFeed(id: FeedID, draft: FeedDraftEntity) async throws
    func deleteFeed(id: FeedID) async throws
    
    func getFeedDetail(id: FeedID) async throws -> FeedDetailEntity
}
