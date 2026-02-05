//
//  DeleteNovelReviewUseCase.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

public protocol DeleteNovelReviewUseCase {
    func execute(novelID: NovelID) async throws
}

public final class DefaultDeleteNovelReviewUseCase: DeleteNovelReviewUseCase {

    private let repository: NovelReviewRepository

    public init(repository: NovelReviewRepository) {
        self.repository = repository
    }

    public func execute(novelID: NovelID) async throws {
        try await repository.deleteNovelReview(novelID: novelID)
    }
}
