//
//  ReportImproperFeedUsecaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain

@Suite(.tags(.usecase))
struct ReportImproperFeedUsecaseTests {
    
    @Test func `부적절한 피드 신고를 성공적으로 요청한다.`() async throws {
        let mock = MockFeedRepository()
        mock.reportImproperResult = .success(())
        
        let usecase = DefaultReportImproperFeedUsecase(feedRepository: mock)
        let feedID = FeedID(1)
        
        try await usecase.execute(feedID: feedID)
        
        #expect(mock.reportedImproperFeedID == feedID)
    }
    
    @Test func `부적절한 피드 신고를 실패하면 에러를 던진다.`() async {
        let mock = MockFeedRepository()
        mock.reportImproperResult = .failure(RepositoryError.networkUnavailable)
        
        let usecase = DefaultReportImproperFeedUsecase(feedRepository: mock)
        
        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.execute(feedID: FeedID(1))
        }
    }
}

