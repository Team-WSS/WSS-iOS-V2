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
    private(set) var getDetailCalled = false
    
    private(set) var receivedFeedID: FeedID?
    private(set) var receivedDraft: FeedDraft?
    
    var stubbedError: Error?
    var stubbedFeedDetail: FeedDetail?
    
    func submitFeed(_ draft: FeedDraft) async throws {
        submitCalled = true
        receivedDraft = draft
    }
    
    func editFeed(id: FeedID, draft: FeedDraft) async throws {
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
    
    func getFeedDetail(id: FeedID) async throws -> FeedDetail {
        if let error = stubbedError { throw error }
        getDetailCalled = true
        receivedFeedID = id
        
        guard let detail = stubbedFeedDetail else {
            fatalError("stubbedFeedDetail must be set before calling getFeedDetail")
        }
        
        return detail
    }
}
