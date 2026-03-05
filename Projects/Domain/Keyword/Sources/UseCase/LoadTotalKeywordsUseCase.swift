//
//  LoadTotalKeywordsUseCase.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadTotalKeywordsUseCase {
    func execute() async throws -> [KeywordGroup]
}

public final class DefaultFetchTotalKeywordsUseCase: LoadTotalKeywordsUseCase {
    
    private let keywordRepository: KeywordRepository
    
    public init(keywordRepository: KeywordRepository) {
        self.keywordRepository = keywordRepository
    }
    
    public func execute() async throws -> [KeywordGroup] {
        try await keywordRepository.fetchKeywords()
    }
}
