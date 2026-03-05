//
//  SearchKeywordUseCase.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol SearchKeywordsUseCase {
    func execute(searchText: String) async throws -> [Keyword]
}

public final class DefaultSearchKeywordUseCase: SearchKeywordsUseCase {
    
    private let keywordRepository: KeywordRepository
    
    init(keywordRepository: KeywordRepository) {
        self.keywordRepository = keywordRepository
    }
    
    public func execute(searchText: String) async throws -> [Keyword] {
        try await keywordRepository.searchKeywords(searchText)
    }
}
