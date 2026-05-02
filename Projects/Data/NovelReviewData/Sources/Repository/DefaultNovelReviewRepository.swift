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
        let action = NovelReviewAction.load

        do {
            let response = try await service.getReview(novelId: novelID.value)
            let result = try NovelReviewMapper.novelReviewDraft(from: response,
                                                                novelID: novelID)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    private func shouldFallbackToPut(from error: NetworkingError) -> Bool {
        guard case let .responseFailure(_, body) = error else { return false }
        return NovelReviewMapper.isAlreadyReviewed(code: body?.code)
    }

    public func save(draft: NovelReviewDraft) async throws(RepositoryError) {
        let postAction = NovelReviewAction.post
        let postRequest = NovelReviewMapper.postNovelReviewRequest(from: draft)

        do {
            try await service.postReview(postRequest)
            logger?.logSuccess(action: postAction.name)
            return
        } catch let error as NetworkingError {
            guard shouldFallbackToPut(from: error) else {
                logger?.logNetworkError(action: postAction.name, error: error)
                throw error.toRepositoryError()
            }
        } catch {
            logger?.logUnknownError(action: postAction.name, error: error)
            throw .unknown
        }

        let putAction = NovelReviewAction.put
        let putRequest = NovelReviewMapper.putNovelReviewRequest(from: draft)

        do {
            try await service.putReview(
                novelId: draft.novelID.value,
                putRequest
            )
            logger?.logSuccess(action: putAction.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: putAction.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: putAction.name, error: error)
            throw .unknown
        }
    }

    public func deleteNovelReview(novelID: NovelID) async throws(RepositoryError) {
        let action = NovelReviewAction.delete

        do {
            try await service.deleteReview(novelId: novelID.value)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
}
