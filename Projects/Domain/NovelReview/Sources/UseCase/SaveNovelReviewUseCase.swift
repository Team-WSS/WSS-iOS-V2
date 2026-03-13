//
//  SaveNovelReviewUseCase.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol SaveNovelReviewUseCase {
    func execute(draft: NovelReviewDraft) async throws(RepositoryError)
}

public final class DefaultSaveNovelReviewUseCase: SaveNovelReviewUseCase {

    private let repository: NovelReviewRepository

    public init(repository: NovelReviewRepository) {
        self.repository = repository
    }

    public func execute(draft: NovelReviewDraft) async throws(RepositoryError) {
        try await repository.save(draft: draft)
    }
}
