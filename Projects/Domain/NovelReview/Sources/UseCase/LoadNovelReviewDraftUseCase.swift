//
//  LoadNovelReviewDraftUseCase.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadNovelReviewDraftUseCase {
    func execute(novelID: NovelID) async throws -> NovelReviewDraft?
}

public final class DefaultLoadNovelReviewDraftUseCase: LoadNovelReviewDraftUseCase {

    private let repository: NovelReviewRepository

    public init(repository: NovelReviewRepository) {
        self.repository = repository
    }

    public func execute(novelID: NovelID) async throws -> NovelReviewDraft? {
        try await repository.loadNovelReviewDraft(novelID: novelID)
    }
}
