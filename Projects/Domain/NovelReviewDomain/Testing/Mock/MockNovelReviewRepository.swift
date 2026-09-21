//
//  MockNovelReviewRepository.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NovelReviewDomain
import BaseDomain

public final class MockNovelReviewRepository: NovelReviewRepository {
    public var loadedNovelID: NovelID?
    public var savedDrafts: [NovelReviewDraft] = []
    public var deletedNovelIDs: [NovelID] = []

    public var loadResult: Result<NovelReviewDraft?, RepositoryError> = .success(nil)
    public var saveResult: Result<Void, RepositoryError> = .success(())
    public var deleteResult: Result<Void, RepositoryError> = .success(())

    public init() {}

    public func loadNovelReviewDraft(novelID: NovelID) async throws(RepositoryError) -> NovelReviewDraft? {
        loadedNovelID = novelID
        switch loadResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    public func save(draft: NovelReviewDraft) async throws(RepositoryError) {
        savedDrafts.append(draft)
        switch saveResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    public func deleteNovelReview(novelID: NovelID) async throws(RepositoryError) {
        deletedNovelIDs.append(novelID)
        switch deleteResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
