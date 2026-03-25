//
//  NovelReviewRepository.swift
//  NovelReviewData
//
//  Created by YunhakLee on 3/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import NovelReviewDomain
import BaseDomain
import Networking

public struct DefaultNovelReviewRepository: NovelReviewRepository {
    private var novelReviewService: NovelReviewService
    
    init(novelReviewService: NovelReviewService) {
        self.novelReviewService = novelReviewService
    }
    
    public func loadNovelReviewDraft(
        novelID: NovelID
    ) async throws(RepositoryError) -> NovelReviewDraft? {
        do {
            let response = try await novelReviewService.getReview(novelId: novelID.value)
            return try NovelReviewMapper.novelReviewDraft(from: response,
                                                          novelID: novelID)
        } catch let error as NovelReviewMapper.MappingError {
            // Log
            throw .invalidData
        } catch let error as NetworkingError {
            throw error.toRepositoryError()
        } catch {
            throw .unknown
        }
    }
    
    private func shouldFallbackToPut(from error: NetworkingError) -> Bool {
        guard case let .responseFailure(_, body) = error else { return false }
        return NovelReviewMapper.isAlreadyReviewed(code: body?.code)
    }
    
    public func save(draft: NovelReviewDraft) async throws(RepositoryError) {
        let postRequest = NovelReviewMapper.postNovelReviewRequest(from: draft)

        do {
            try await novelReviewService.postReview(postRequest)
            return
        } catch let error as NetworkingError {
            // Put으로 넘겨야 하는 경우에는 throw가 실행되지 않도록
            guard shouldFallbackToPut(from: error) else {
                throw error.toRepositoryError()
            }
        } catch {
            throw .unknown
        }

        let putRequest = NovelReviewMapper.putNovelReviewRequest(from: draft)

        do {
            try await novelReviewService.putReview(
                novelId: draft.novelID.value,
                putRequest
            )
        } catch let error as NetworkingError {
            throw error.toRepositoryError()
        } catch {
            throw .unknown
        }
    }
    
    public func deleteNovelReview(novelID: NovelID) async throws(RepositoryError) {
        do {
            try await novelReviewService.deleteReview(novelId: novelID.value)
        } catch let error as NetworkingError {
            throw error.toRepositoryError()
        } catch {
            throw .unknown
        }
    }
}
