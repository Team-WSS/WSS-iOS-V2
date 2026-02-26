//
//  SearchNovelUsecase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol SearchNovelUsecase {
    func searchByText(_ query: String) async throws -> (Paginated<Novel>, Int)
    func searchByFilter(_ filter: SearchFilter) async throws -> (Paginated<Novel>, Int)
}

public final class DefaultSearchNovelUsecase: SearchNovelUsecase {
    
    private let novelRepository: NovelRepository
    
    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }
    
    public func searchByText(_ query: String) async throws -> (Paginated<Novel>, Int) {
        try await novelRepository.searchNovelByText(query)
    }
    
    public func searchByFilter(_ filter: SearchFilter) async throws -> (Paginated<Novel>, Int) {
        try await novelRepository.searchNovelByFilter(filter)
    }
}
