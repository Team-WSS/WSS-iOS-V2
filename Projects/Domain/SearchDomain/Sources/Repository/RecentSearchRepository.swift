//
//  RecentSearchRepository.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol RecentSearchRepository: Sendable {
    /// 서버에 기록된 최근 검색어를 최신순으로 조회한다. (검색 실행 시 서버가 자동 기록 — 클라이언트의 별도 add 호출 없음)
    func fetchRecentSearchWords() async throws(RepositoryError) -> [RecentSearchWord]
    /// 서버에 기록된 최근 검색어 하나를 제거한다.
    func removeRecentSearchWord(_ word: RecentSearchWord) async throws(RepositoryError)
    /// 서버에 기록된 최근 검색어를 전체 삭제한다.
    func clearRecentSearchWords() async throws(RepositoryError)
}
