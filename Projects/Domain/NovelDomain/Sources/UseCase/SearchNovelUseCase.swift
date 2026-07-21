//
//  SearchNovelUseCase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol SearchNovelUseCase {
    /// `page`는 0부터 시작하는 페이지 번호 — 무한스크롤 다음 페이지 요청 시 호출 측이 증가시켜 넘긴다.
    func searchByText(_ query: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int)
    func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int)
}

public final class DefaultSearchNovelUseCase: SearchNovelUseCase {

    private let novelRepository: NovelRepository

    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }

    public func searchByText(_ query: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        try await novelRepository.searchNovelByText(query, page: page)
    }

    public func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        try await novelRepository.searchNovelByFilter(filter, page: page)
    }
}
