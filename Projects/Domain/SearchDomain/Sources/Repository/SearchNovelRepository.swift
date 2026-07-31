//
//  SearchNovelRepository.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol SearchNovelRepository {
    /// `page`는 0부터 시작 — 무한스크롤 다음 페이지 요청 시 호출 측이 증가시켜 넘긴다.
    func searchNovelByText(_ text: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int)
    func searchNovelByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int)
}
