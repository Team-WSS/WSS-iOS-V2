//
//  LoadUserRegisteredNovelStatsUseCase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 7/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadUserRegisteredNovelStatsUseCase {
    func execute(id: UserID) async throws(RepositoryError) -> RegisteredNovelStats
}

public final class DefaultLoadUserRegisteredNovelStatsUseCase: LoadUserRegisteredNovelStatsUseCase {

    private let novelRepository: NovelRepository

    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }

    public func execute(id: UserID) async throws(RepositoryError) -> RegisteredNovelStats {
        try await novelRepository.fetchUserRegisteredNovelStats(id: id)
    }
}
