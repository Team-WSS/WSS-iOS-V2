//
//  MockNovelReviewRepository 2.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//



import Foundation
import Testing
import NovelReviewDomain

// MARK: - Test Doubles

final class MockNovelReviewRepository: NovelReviewRepository {
    var loadedNovelID: NovelID?
    var savedDrafts: [NovelReviewDraft] = []
    var deletedNovelIDs: [NovelID] = []

    var loadResult: Result<NovelReviewDraft?, RepositoryError> = .success(nil)
    var saveResult: Result<Void, RepositoryError> = .success(())
    var deleteResult: Result<Void, RepositoryError> = .success(())

    func loadNovelReviewDraft(novelID: NovelID) async throws(RepositoryError) -> NovelReviewDraft? {
        loadedNovelID = novelID
        switch loadResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func save(draft: NovelReviewDraft) async throws(RepositoryError) {
        savedDrafts.append(draft)
        switch saveResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func deleteNovelReview(novelID: NovelID) async throws(RepositoryError) {
        deletedNovelIDs.append(novelID)
        switch deleteResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
