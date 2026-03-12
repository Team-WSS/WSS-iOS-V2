//
//  ReportSpoilerCommentUseCase.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol ReportSpoilerCommentUseCase {
    func execute(id: CommentID) async throws(RepositoryError)
}

public final class DefaultReportSpoilerCommentUseCase: ReportSpoilerCommentUseCase {
    private let repository: SocialRepository
    
    public init(repository: SocialRepository) {
        self.repository = repository
    }
    
    public func execute(id: CommentID) async throws(RepositoryError) {
        try await repository.reportSpoilerComment(id: id)
    }
}
