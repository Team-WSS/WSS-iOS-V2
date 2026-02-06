//
//  SearchKeywordUsecase.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol SearchKeywordUsecase {
    func execute(searchText: String) async throws -> [Keyword]
}

public final class DefaultSearchKeywordUsecase: SearchKeywordUsecase {
    
    private let repository: KeywordRepositoryProtocol
    
    init(repository: KeywordRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(searchText: String) async throws -> [Keyword] {
        let groups = try await repository.fetchKeyword(searchText)
        
        return groups.flatMap { $0.keywords }
    }
}
