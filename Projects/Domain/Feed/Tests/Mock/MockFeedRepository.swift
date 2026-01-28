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
    private(set) var receivedDraft: FeedDraftEntity?

    func submitFeed(_ draft: FeedDraftEntity) async throws {
        submitCalled = true
        receivedDraft = draft
    }
}
