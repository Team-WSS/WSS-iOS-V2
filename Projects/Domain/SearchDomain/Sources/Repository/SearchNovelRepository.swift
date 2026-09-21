//
//  SearchNovelRepository.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol SearchNovelRepository: Sendable {
    /// `page`는 0부터 시작 — 무한스크롤 다음 페이지 요청 시 호출 측이 증가시켜 넘긴다.
    /// `recordRecentSearch`: 이번 검색어를 서버가 최근 검색어로 저장할지. 사용자가 검색을 목적으로
    /// 직접 실행한 호출(일반 검색 화면)만 `true` — 작품 연결·컬렉션에 작품 담기처럼 검색이 부수
    /// 수단인 화면은 `false`로 넘겨야 한다(기본값 없음 — 호출부가 매번 명시적으로 결정하게 강제).
    func searchNovelByText(
        _ text: String,
        page: Int,
        recordRecentSearch: Bool
    ) async throws(RepositoryError) -> (Paginated<Novel>, Int)
    func searchNovelByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int)
}
