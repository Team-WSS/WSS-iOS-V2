//
//  LoadUserLibraryUsecase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol LoadUserLibraryUsecase {
    func execute(id: UserID) async throws -> (Paginated<LibraryNovel>, Int)
}

public final class DefaultLoadUserLibraryUsecase: LoadUserLibraryUsecase {
    
    private let novelRepository: NovelRepository
    
    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }
    
    public func execute(id: UserID) async throws -> (Paginated<LibraryNovel>, Int) {
        return try await novelRepository.fetchUserLibraryNovels(id: id)
    }
}
