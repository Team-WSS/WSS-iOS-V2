//
//  LoadMyLibraryUsecase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol LoadMyLibraryUsecase {
    func execute(_ filter: MyLibraryFilter) async throws -> Paginated<LibraryNovel>
}

public final class DefaultLoadMyLibraryUsecase: LoadMyLibraryUsecase {
    
    private let novelRepository: NovelRepository
    
    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }
    
    public func execute(_ filter: MyLibraryFilter) async throws -> Paginated<LibraryNovel> {
        try await novelRepository.fetchMyLibraryNovels(filter)
    }
}
