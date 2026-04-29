//
//  DefaultNovelReviewRepository.swift
//  NovelReviewData
//
//  Created by YunhakLee on 3/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import NovelReviewDomain
import BaseDomain
import BaseData
import Networking

public struct DefaultNovelReviewRepository: NovelReviewRepository {
    private let service: NovelReviewService
    private let logger: DataLogger?

    init(
        novelReviewService: NovelReviewService,
        logger: DataLogger?
    ) {
        self.service = novelReviewService
        self.logger = logger
    }

    public func loadNovelReviewDraft(novelID: NovelID) async throws(RepositoryError) -> NovelReviewDraft? {
        do {
            let response = try await service.getReview(novelId: novelID.value)
            let result = try NovelReviewMapper.novelReviewDraft(from: response,
                                                                novelID: novelID)
            logger?.logSuccess(action: "load")
            return result
        } catch let error as MappingError {
            logger?.logMappingError(action: "load", error: error)
            throw .invalidData
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: "load", error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: "load", error: error)
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
            try await service.postReview(postRequest)
            logger?.logSuccess(action: "post")
            return
        } catch let error as NetworkingError {
            guard shouldFallbackToPut(from: error) else {
                logger?.logNetworkError(action: "post", error: error)
                throw error.toRepositoryError()
            }
        } catch {
            logger?.logUnknownError(action: "post", error: error)
            throw .unknown
        }

        let putRequest = NovelReviewMapper.putNovelReviewRequest(from: draft)

        do {
            try await service.putReview(
                novelId: draft.novelID.value,
                putRequest
            )
            logger?.logSuccess(action: "put")
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: "put", error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: "put", error: error)
            throw .unknown
        }
    }

    public func deleteNovelReview(novelID: NovelID) async throws(RepositoryError) {
        do {
            try await service.deleteReview(novelId: novelID.value)
            logger?.logSuccess(action: "delete")
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: "delete", error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: "delete", error: error)
            throw .unknown
        }
    }
}
