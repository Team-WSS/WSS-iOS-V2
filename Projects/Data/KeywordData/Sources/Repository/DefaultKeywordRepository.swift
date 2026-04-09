//
//  DefaultKeywordRepository.swift
//  KeywordData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import KeywordDomain
import BaseDomain

public struct DefaultKeywordRepository: KeywordRepository {
    
    private let keywordService: KeywordService
    
    init(
        keywordService: KeywordService
    ) {
        self.keywordService = keywordService
    }
    
    // 전체 키워드 조회
    public func fetchKeywords() async throws(RepositoryError) -> [KeywordGroup] {
        do {
            let query = SearchKeywordRequest(query: "")
            let response = try await keywordService.searchKeyword(query)
            return KeywordMapper.keywordGroups(from: response)
        } catch {
            
        }
    }
    
    // 특정 키워드 검색
    public func searchKeywords(_ query: String) async throws(RepositoryError) -> [KeywordGroup] {
        do {
            let request = SearchKeywordRequest(query: query)
            let response = try await keywordService.searchKeyword(request)
            return KeywordMapper.keywordGroups(from: response)
        } catch {
            
        }
    }
}
