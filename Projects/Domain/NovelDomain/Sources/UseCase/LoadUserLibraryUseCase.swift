//
//  LoadUserLibraryUseCase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadUserLibraryUseCase: Sendable {
    /// - Parameters:
    ///   - id: 조회 대상 사용자.
    ///   - cursor: 직전 페이지 응답의 `nextCursor`. 첫 페이지는 nil.
    func execute(
        id: UserID,
        filter: LibraryFilter,
        cursor: String?
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int)
}

public final class DefaultLoadUserLibraryUseCase: LoadUserLibraryUseCase {

    private let novelRepository: NovelRepository
    private let keywordRepository: KeywordRepository

    public init(
        novelRepository: NovelRepository,
        keywordRepository: KeywordRepository
    ) {
        self.novelRepository = novelRepository
        self.keywordRepository = keywordRepository
    }

    public func execute(
        id: UserID,
        filter: LibraryFilter,
        cursor: String?
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        // 서버는 키워드 이름만 내려주므로, 로컬 캐시에서 ID를 찾아 셀에 표시할 `Keyword`로 복원한다.
        // 캐시 조회 실패가 서재 목록 자체를 막지 않도록 내 서재와 동일하게 빈 배열로 폴백한다.
        let cachedKeywords = (try? await keywordRepository.fetchKeywords())?.flatMap(\.keywords) ?? []
        return try await novelRepository.fetchUserLibraryNovels(
            id: id,
            filter,
            cursor: cursor,
            cachedKeywords: cachedKeywords
        )
    }
}
