//
//  LoadPopularKeywordsUseCase.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadPopularKeywordsUseCase {
    func execute() async throws(RepositoryError) -> PopularKeywords
}

public final class DefaultLoadPopularKeywordsUseCase: LoadPopularKeywordsUseCase {

    private let keywordRepository: KeywordRepository

    public init(keywordRepository: KeywordRepository) {
        self.keywordRepository = keywordRepository
    }

    public func execute() async throws(RepositoryError) -> PopularKeywords {
        try await keywordRepository.fetchPopularKeywords()
    }
}
