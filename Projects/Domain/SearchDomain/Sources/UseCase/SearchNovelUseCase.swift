//
//  SearchNovelUseCase.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol SearchNovelUseCase: Sendable {
    /// `recordRecentSearch`: 이번 검색어를 서버가 최근 검색어로 저장할지 — `SearchNovelRepository`
    /// 문서 참고. 기본값을 두지 않는다: 호출부가 "이게 사용자가 의도한 검색인가"를 매번 판단하게 한다.
    func searchByText(
        _ query: String,
        page: Int,
        recordRecentSearch: Bool
    ) async throws(RepositoryError) -> (Paginated<Novel>, Int)
    func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int)
}

public final class DefaultSearchNovelUseCase: SearchNovelUseCase {

    private let searchNovelRepository: SearchNovelRepository

    public init(searchNovelRepository: SearchNovelRepository) {
        self.searchNovelRepository = searchNovelRepository
    }

    public func searchByText(
        _ query: String,
        page: Int,
        recordRecentSearch: Bool
    ) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        try await searchNovelRepository.searchNovelByText(query, page: page, recordRecentSearch: recordRecentSearch)
    }

    public func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        try await searchNovelRepository.searchNovelByFilter(filter, page: page)
    }
}
