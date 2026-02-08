//
//  SearchKeywordsUsecaseTests.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import KeywordDomain
@testable import BaseDomain

//TODO: testing tags 붙이기
@Suite
struct SearchKeywordsUsecaseTests {
    
    @Test func `특정 키워드 검색시 성공적으로 불러온다.`() async throws {
        let mock = MockKeywordRepository()
        
        let expected = [
            Keyword(id: KeywordID(10), name: "삼국지"),
            Keyword(id: KeywordID(11), name: "성장"),
            Keyword(id: KeywordID(12), name: "환생")
        ]
        
        mock.searchKeywordsResult = .success(expected)
        
        let query = "삼국지"
        
        let result = try await mock.searchKeywords(query)
        
        #expect(result.count == 3)
        #expect(result.first?.name == "삼국지")
        #expect(mock.searchKeywordsCallCount == 1)
        #expect(mock.lastSearchQuery == query)
    }
    
    @Test func `특정 키워드 검색 실패 시 에러를 던진다`() async {
        let mock = MockKeywordRepository()
        
        //TODO: Repository Error로 수정
        enum TestError: Error { case searchFail }
        
        mock.searchKeywordsResult = .failure(TestError.searchFail)

        await #expect(throws: TestError.searchFail) {
            try await mock.searchKeywords("집착")
        }
        
        #expect(mock.searchKeywordsCallCount == 1)
        #expect(mock.lastSearchQuery == "집착")
    }
    
}
