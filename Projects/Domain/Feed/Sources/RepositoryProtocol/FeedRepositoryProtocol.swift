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
}
