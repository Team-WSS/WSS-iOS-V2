//
//  NovelReviewRepository.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import BaseDomain

public protocol NovelReviewRepository {

    func loadNovelReviewDraft(
        novelID: NovelID
    ) async throws(RepositoryError) -> NovelReviewDraft?

    func save(
        draft: NovelReviewDraft
    ) async throws(RepositoryError)

    func deleteNovelReview(
        novelID: NovelID
    ) async throws(RepositoryError)
}
