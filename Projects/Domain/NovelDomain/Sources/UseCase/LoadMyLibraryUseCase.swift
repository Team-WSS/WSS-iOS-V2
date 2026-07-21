//
//  LoadMyLibraryUseCase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadMyLibraryUseCase {
    /// - Parameter cursor: 직전 페이지 응답의 `nextCursor`. 첫 페이지는 nil.
    func execute(filter: MyLibraryFilter, cursor: String?) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int)
}

public final class DefaultLoadMyLibraryUseCase: LoadMyLibraryUseCase {

    private let novelRepository: NovelRepository

    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }

    public func execute(filter: MyLibraryFilter, cursor: String?) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        try await novelRepository.fetchMyLibraryNovels(filter, cursor: cursor)
    }
}
