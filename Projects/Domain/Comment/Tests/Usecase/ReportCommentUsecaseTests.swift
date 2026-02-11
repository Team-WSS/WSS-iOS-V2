//
//  ReportCommentUsecaseTests.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import CommentDomain
@testable import BaseDomain

@Suite
struct ReportSpoilerCommentUsecaseTests {
    
    @Test func `스포일러 댓글 신고를 성공적으로 요청한다.`() async throws {
        let mock = MockCommentRepository()
        mock.reportSpoilerResult = .success(())
        
        let usecase = DefaultReportCommentUsecase(commentRepository: mock)
        let commentID = CommentID(1)
        
        try await usecase.reportSpoilerComment(id: commentID)
        
        #expect(mock.reportedSpoilerCommentID == commentID)
    }
    
    @Test func `스포일러 댓글 신고를 실패하면 에러를 던진다.`() async {
        let mock = MockCommentRepository()
        mock.reportSpoilerResult = .failure(RepositoryError.networkUnavailable)
        
        let usecase = DefaultReportCommentUsecase(commentRepository: mock)
        
        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.reportSpoilerComment(id: CommentID(1))
        }
    }
    
    @Test func `부적절한 댓글 신고를 성공적으로 요청한다.`() async throws {
        let mock = MockCommentRepository()
        mock.reportImproperResult = .success(())
        
        let usecase = DefaultReportCommentUsecase(commentRepository: mock)
        let commentID = CommentID(1)
        
        try await usecase.reportImproperComment(id: commentID)
        
        #expect(mock.reportedImproperCommentID == commentID)
    }
    
    @Test func `부적절한 댓글 신고를 실패하면 에러를 던진다.`() async {
        let mock = MockCommentRepository()
        mock.reportImproperResult = .failure(RepositoryError.networkUnavailable)
        
        let usecase = DefaultReportCommentUsecase(commentRepository: mock)
        
        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.reportImproperComment(id: CommentID(1))
        }
    }
}
