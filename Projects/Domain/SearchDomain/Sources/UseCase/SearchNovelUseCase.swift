//
//  SearchNovelUseCase.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol SearchNovelUseCase {
    func searchByText(_ query: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int)
    func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int)
}

public final class DefaultSearchNovelUseCase: SearchNovelUseCase {

    private let searchNovelRepository: SearchNovelRepository

    public init(searchNovelRepository: SearchNovelRepository) {
        self.searchNovelRepository = searchNovelRepository
    }

    public func searchByText(_ query: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        try await searchNovelRepository.searchNovelByText(query, page: page)
    }

    public func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        try await searchNovelRepository.searchNovelByFilter(filter, page: page)
    }
}
