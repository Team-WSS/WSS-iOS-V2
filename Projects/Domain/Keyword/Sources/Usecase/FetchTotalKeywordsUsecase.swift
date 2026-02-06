//
//  FetchTotalKeywordsUsecase.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol FetchTotalKeywordsUsecase {
    func execute() async throws -> [KeywordGroup]
}

public final class DefaultFetchTotalKeywordsUsecase: FetchTotalKeywordsUsecase {
    
    private let keywordRepository: KeywordRepositoryProtocol
    
    public init(keywordRepository: KeywordRepositoryProtocol) {
        self.keywordRepository = keywordRepository
    }
    
    public func execute() async throws -> [KeywordGroup] {
        try await keywordRepository.fetchKeyword(nil)
    }
}
