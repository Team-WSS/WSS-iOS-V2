//
//  FeedUsecaseProtocol.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol FeedUsecaseProtocol {
    func createFeed(draft: FeedDraftEntity) async throws
}
