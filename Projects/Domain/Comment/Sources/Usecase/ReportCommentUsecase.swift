//
//  ReportCommentUsecase.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol ReportCommentUsecase {
    func reportSpoilerComment(id: CommentID) async throws
    func reportImproperComment(id: CommentID) async throws
}

public final class DefaultReportCommentUsecase: ReportCommentUsecase {
    
    private let commentRepository: CommentRepository
    
    public init(commentRepository: CommentRepository) {
        self.commentRepository = commentRepository
    }
    
    public func reportSpoilerComment(id: CommentID) async throws {
        try await commentRepository.reportSpoilerComment(id: id)
    }
    
    public func reportImproperComment(id: CommentID) async throws {
        try await commentRepository.reportImproperComment(id: id)
    }
}
