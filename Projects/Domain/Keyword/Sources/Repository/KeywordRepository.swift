//
//  KeywordRepositoryProtocol.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public protocol KeywordRepository {
    // 전체 키워드 조회
    func fetchKeywords() async throws -> [KeywordGroup]
    // 특정 키워드 검색
    func searchKeywords(_ query: String) async throws -> [Keyword]
}
