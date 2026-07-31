//
//  MockSearchAutoCompletionRepository.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import SearchDomain
import BaseDomain

public final class MockSearchAutoCompletionRepository: SearchAutoCompletionRepository {

    public var fetchAutoCompletionWordsResult: Result<[SearchAutoCompletionWord], RepositoryError> = .success([])

    public private(set) var searchedTexts: [String] = []

    public init() {}

    public func fetchAutoCompletionWords(searchText: String) async throws(RepositoryError) -> [SearchAutoCompletionWord] {
        searchedTexts.append(searchText)
        return try fetchAutoCompletionWordsResult.get()
    }
}
