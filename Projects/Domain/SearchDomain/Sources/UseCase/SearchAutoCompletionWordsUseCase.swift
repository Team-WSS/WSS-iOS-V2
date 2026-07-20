//
//  SearchAutoCompletionWordsUseCase.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol SearchAutoCompletionWordsUseCase {
    func execute(searchText: String) async throws(RepositoryError) -> [SearchAutoCompletionWord]
}

public final class DefaultSearchAutoCompletionWordsUseCase: SearchAutoCompletionWordsUseCase {

    private let searchAutoCompletionRepository: SearchAutoCompletionRepository

    public init(searchAutoCompletionRepository: SearchAutoCompletionRepository) {
        self.searchAutoCompletionRepository = searchAutoCompletionRepository
    }

    public func execute(searchText: String) async throws(RepositoryError) -> [SearchAutoCompletionWord] {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return [] }
        return try await searchAutoCompletionRepository.fetchAutoCompletionWords(searchText: trimmedText)
    }
}
