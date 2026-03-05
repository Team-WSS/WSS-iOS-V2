//
//  ReportImproperFeedUseCase.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol ReportImproperFeedUseCase {
    func execute(id: FeedID) async throws
}

public final class DefaultReportImproperFeedUseCase: ReportImproperFeedUseCase {
    private let repository: SocialRepository

    public init(repository: SocialRepository) {
        self.repository = repository
    }
    
    public func execute(id: FeedID) async throws {
        try await repository.reportImproperFeed(id: id)
    }
}
