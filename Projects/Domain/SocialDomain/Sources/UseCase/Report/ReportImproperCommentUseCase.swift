//
//  ReportImproperCommentUseCase.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import BaseDomain

public protocol ReportImproperCommentUseCase {
    func execute(id: CommentID) async throws
}

public final class DefaultReportImproperCommentUseCase: ReportImproperCommentUseCase {

    private let repository: SocialRepository
    
    public init(repository: SocialRepository) {
        self.repository = repository
    }
    
    public func execute(id: CommentID) async throws {
        try await repository.reportImproperComment(id: id)
    }
}
