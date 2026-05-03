//
//  KeywordRepository.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol KeywordRepository {
    /// 로컬 DB에서 전체 키워드를 조회한다.
    func fetchKeywords() async throws(RepositoryError) -> [KeywordGroup]
    /// 로컬 DB에서 키워드를 검색한다.
    func searchKeywords(_ query: String) async throws(RepositoryError) -> [KeywordGroup]
    /// 서버에서 키워드를 가져와 로컬 DB와 동기화한다.
    func syncKeywords() async
}
