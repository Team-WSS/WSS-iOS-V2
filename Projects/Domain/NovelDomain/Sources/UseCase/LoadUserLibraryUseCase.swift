//
//  LoadUserLibraryUseCase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadUserLibraryUseCase {
    func execute(id: UserID, _ filter: LibraryFilter) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int)
}

public final class DefaultLoadUserLibraryUseCase: LoadUserLibraryUseCase {
    
    private let novelRepository: NovelRepository
    
    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }
    
    public func execute(id: UserID,
                        _ filter: LibraryFilter) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int) {
        return try await novelRepository.fetchUserLibraryNovels(id: id, filter)
    }
}
