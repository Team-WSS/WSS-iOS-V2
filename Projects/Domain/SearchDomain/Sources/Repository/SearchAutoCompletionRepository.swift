//
//  SearchAutoCompletionRepository.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol SearchAutoCompletionRepository: Sendable {
    /// 입력 중인 검색어에 대한 제목 기반 자동완성 후보를 서버에서 조회한다.
    func fetchAutoCompletionWords(searchText: String) async throws(RepositoryError) -> [SearchAutoCompletionWord]
}
