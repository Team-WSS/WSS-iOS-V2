//
//  LoadRegisteredNovelStatsUseCase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadRegisteredNovelStatsUseCase {
    func execute() async throws(RepositoryError) -> RegisteredNovelStats
}

public final class DefaultLoadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase {
    
    private let novelRepository: NovelRepository
    
    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }
    
    public func execute() async throws(RepositoryError) -> RegisteredNovelStats {
        try await novelRepository.fetchRegisteredNovelStats()
    }
}
