//
//  LoadNovelUseCase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadNovelUseCase {
    func execute(id: NovelID) async throws(RepositoryError) -> NovelInformation
}

public final class DefaultLoadNovelUseCase: LoadNovelUseCase {

    private let novelRepository: NovelRepository

    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }

    public func execute(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        return try await novelRepository.fetchNovel(id: id)
    }
}
