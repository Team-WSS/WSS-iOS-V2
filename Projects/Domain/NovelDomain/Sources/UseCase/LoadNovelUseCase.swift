//
//  LoadNovelUseCase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadNovelUseCase: Sendable {
    func execute(id: NovelID) async throws(RepositoryError) -> NovelInformation
}

public final class DefaultLoadNovelUseCase: LoadNovelUseCase {

    private let novelRepository: NovelRepository
    /// 캐시 미스 시 서버 재동기화까지 책임지는 건 `KeywordRepository`가 아니라 이 UseCase 몫이다 —
    /// `BaseDomain/CLAUDE.md`의 `LoadTotalKeywordsUseCase` 항목 참고(2026-09-12, 사용자 확정).
    private let loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase

    public init(novelRepository: NovelRepository,
                loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase) {
        self.novelRepository = novelRepository
        self.loadTotalKeywordsUseCase = loadTotalKeywordsUseCase
    }

    public func execute(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        let cachedKeywords = (try? await loadTotalKeywordsUseCase.execute())?.flatMap(\.keywords) ?? []
        return try await novelRepository.fetchNovel(id: id, cachedKeywords: cachedKeywords)
    }
}
