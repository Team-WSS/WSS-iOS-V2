//
//  LoadTotalKeywordsUseCase.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadTotalKeywordsUseCase {
    func execute() async throws(RepositoryError) -> [KeywordGroup]
}

public final class DefaultFetchTotalKeywordsUseCase: LoadTotalKeywordsUseCase {

    private let keywordRepository: KeywordRepository

    public init(keywordRepository: KeywordRepository) {
        self.keywordRepository = keywordRepository
    }

    public func execute() async throws(RepositoryError) -> [KeywordGroup] {
        do {
            return try await keywordRepository.fetchKeywords()
        } catch {
            // 로컬 캐시가 비어있는 최초 실행 등 조회 실패 시, 서버 동기화를 한 번 시도한 뒤 재조회한다.
            // syncKeywords()는 throw하지 않으므로 동기화 자체가 실패해도 재조회 결과(원래 에러)를 그대로 전달한다.
            await keywordRepository.syncKeywords()
            return try await keywordRepository.fetchKeywords()
        }
    }
}
