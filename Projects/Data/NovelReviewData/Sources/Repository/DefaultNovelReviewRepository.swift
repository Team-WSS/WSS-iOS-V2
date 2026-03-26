//
//  DefaultNovelReviewRepository.swift
//  NovelReviewData
//
//  Created by YunhakLee on 3/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import NovelReviewDomain
import BaseDomain
import Logger
import Networking

public struct DefaultNovelReviewRepository: NovelReviewRepository {
    private let novelReviewService: NovelReviewService
    private let logger: NovelReviewLogger?
    
    init(
        novelReviewService: NovelReviewService,
        logger: NovelReviewLogger?
    ) {
        self.novelReviewService = novelReviewService
        self.logger = logger
    }
    
    public func loadNovelReviewDraft(novelID: NovelID) async throws(RepositoryError) -> NovelReviewDraft? {
        do {
            let response = try await novelReviewService.getReview(novelId: novelID.value)
            return try NovelReviewMapper.novelReviewDraft(from: response,
                                                          novelID: novelID)
        } catch let error as MappingError {
            logger?.logError(type: .mapping, action: .load, error: error)
            throw .invalidData
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .load, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .load, error: error)
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
            guard shouldFallbackToPut(from: error) else {
                logger?.logError(type: .network, action: .post, error: error)
                throw error.toRepositoryError()
            }
        } catch {
            logger?.logError(type: .unknown, action: .post, error: error)
            throw .unknown
        }

        let putRequest = NovelReviewMapper.putNovelReviewRequest(from: draft)

        do {
            try await novelReviewService.putReview(
                novelId: draft.novelID.value,
                putRequest
            )
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .put, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .put, error: error)
            throw .unknown
        }
    }
    
    public func deleteNovelReview(novelID: NovelID) async throws(RepositoryError) {
        do {
            try await novelReviewService.deleteReview(novelId: novelID.value)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .delete, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .delete, error: error)
            throw .unknown
        }
    }
}
