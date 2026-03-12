//
//  LoadTotalKeywordsUseCase.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadTotalKeywordsUseCase {
    func execute() async throws(RepositoryError) -> [KeywordGroup]
}

public final class DefaultFetchTotalKeywordsUseCase: LoadTotalKeywordsUseCase {
    
    private let keywordRepository: KeywordRepository
    
    public init(keywordRepository: KeywordRepository) {
        self.keywordRepository = keywordRepository
    }
    
    public func execute() async throws(RepositoryError) -> [KeywordGroup] {
        try await keywordRepository.fetchKeywords()
    }
}
