//
//  MockFeedRepository.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import FeedDomain

final class MockFeedRepository: FeedRepositoryProtocol {
    
    private(set) var submitCalled = false
    private(set) var editCalled = false
    private(set) var deleteCalled = false
    
    private(set) var receivedFeedID: FeedID?
    private(set) var receivedDraft: FeedDraftEntity?
    
    var stubbedError: Error?
    
    func submitFeed(_ draft: FeedDraftEntity) async throws {
        submitCalled = true
        receivedDraft = draft
    }
    
    func editFeed(id: FeedID, draft: FeedDraftEntity) async throws {
        if let error = stubbedError { throw error }
        editCalled = true
        receivedFeedID = id
        receivedDraft = draft
    }
    
    func deleteFeed(id: FeedID) async throws {
        if let error = stubbedError { throw error }
        deleteCalled = true
        receivedFeedID = id
    }
}
