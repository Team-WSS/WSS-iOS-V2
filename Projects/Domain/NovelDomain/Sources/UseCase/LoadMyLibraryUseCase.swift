//
//  LoadMyLibraryUseCase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadMyLibraryUseCase: Sendable {
    /// - Parameters:
    ///   - cursor: 직전 페이지 응답의 `nextCursor`. 첫 페이지는 nil.
    ///   - size: 이번 요청으로 받을 개수. 화면이 정한다 — 무한 스크롤은 한 페이지지만, 재진입 갱신은
    ///     "보고 있던 개수만큼"을 한 번에 받아야 목록이 짧아지지 않는다(스크롤 위치가 튄다).
    func execute(
        filter: MyLibraryFilter,
        cursor: String?,
        size: Int
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int)
}

public final class DefaultLoadMyLibraryUseCase: LoadMyLibraryUseCase {

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
        filter: MyLibraryFilter,
        cursor: String?,
        size: Int
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        // 서버는 키워드 이름만 내려주므로, 로컬 캐시에서 ID를 찾아 셀에 표시할 `Keyword`로 복원한다.
        // 캐시 조회 실패가 서재 목록 자체를 막지 않도록 기존 작품 상세과 동일하게 빈 배열로 폴백한다.
        let cachedKeywords = (try? await keywordRepository.fetchKeywords())?.flatMap(\.keywords) ?? []
        return try await novelRepository.fetchMyLibraryNovels(
            filter,
            cursor: cursor,
            size: size,
            cachedKeywords: cachedKeywords
        )
    }
}
