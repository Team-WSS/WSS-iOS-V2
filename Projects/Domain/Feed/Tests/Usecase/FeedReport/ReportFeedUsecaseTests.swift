//
//  ReportSpoilerFeedUsecaseTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain
@testable import BaseDomain

@Suite
struct ReportSpoilerFeedUsecaseTests {
    
    @Test func `스포일러 신고를 성공적으로 요청한다.`() async throws {
        let mock = MockFeedRepository()
        mock.reportSpoilerResult = .success(())
        
        let usecase = DefaultReportFeedUsecase(feedRepository: mock)
        let feedID = FeedID(1)
        
        try await usecase.reportSpoilerFeed(id: feedID)
        
        #expect(mock.reportedSpoilerFeedID == feedID)
    }
    
    @Test func `스포일러 신고를 실패하면 에러를 던진다.`() async {
        let mock = MockFeedRepository()
        mock.reportSpoilerResult = .failure(RepositoryError.networkUnavailable)
        
        let usecase = DefaultReportFeedUsecase(feedRepository: mock)
        
        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.reportSpoilerFeed(id: FeedID(1))
        }
    }
    
    @Test func `부적절한 피드 신고를 성공적으로 요청한다.`() async throws {
        let mock = MockFeedRepository()
        mock.reportImproperResult = .success(())
        
        let usecase = DefaultReportFeedUsecase(feedRepository: mock)
        let feedID = FeedID(1)
        
        try await usecase.reportImproperFeed(id: feedID)
        
        #expect(mock.reportedImproperFeedID == feedID)
    }
    
    @Test func `부적절한 피드 신고를 실패하면 에러를 던진다.`() async {
        let mock = MockFeedRepository()
        mock.reportImproperResult = .failure(RepositoryError.networkUnavailable)
        
        let usecase = DefaultReportFeedUsecase(feedRepository: mock)
        
        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.reportImproperFeed(id: FeedID(1))
        }
    }
}
