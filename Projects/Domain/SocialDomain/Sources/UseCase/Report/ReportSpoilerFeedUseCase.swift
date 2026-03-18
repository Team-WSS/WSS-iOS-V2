//
//  ReportSpoilerFeedUseCase.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol ReportSpoilerFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError)
}

public final class DefaultReportSpoilerFeedUseCase: ReportSpoilerFeedUseCase {
    private let repository: SocialRepository

    public init(repository: SocialRepository) {
        self.repository = repository
    }

    public func execute(id: FeedID) async throws(RepositoryError) {
        try await repository.reportSpoilerFeed(id: id)
    }
}
