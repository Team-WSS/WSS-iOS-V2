//
//  SaveNovelReviewUseCase.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

public protocol SaveNovelReviewUseCase {
    func execute(draft: NovelReviewDraft) async throws
}

public final class DefaultSaveNovelReviewUseCase: SaveNovelReviewUseCase {

    private let repository: NovelReviewRepository

    public init(repository: NovelReviewRepository) {
        self.repository = repository
    }

    public func execute(draft: NovelReviewDraft) async throws {
        try await repository.save(draft: draft)
    }
}
