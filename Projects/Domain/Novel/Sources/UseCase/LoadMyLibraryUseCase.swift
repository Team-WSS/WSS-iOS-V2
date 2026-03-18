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
    func execute(_ filter: MyLibraryFilter) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int)
}

public final class DefaultLoadMyLibraryUseCase: LoadMyLibraryUseCase {
    
    private let novelRepository: NovelRepository
    
    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }
    
    public func execute(_ filter: MyLibraryFilter) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int) {
        try await novelRepository.fetchMyLibraryNovels(filter)
    }
}
