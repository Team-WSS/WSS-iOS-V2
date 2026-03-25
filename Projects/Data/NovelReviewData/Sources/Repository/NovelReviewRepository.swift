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
        return body?.code == "USER_NOVEL-001"
    }
    
    public func save(draft: NovelReviewDraft) async throws(RepositoryError) {
        let postRequest = NovelReviewMapper.postNovelReviewRequest(from: draft)

        do {
            try await novelReviewService.postReview(postRequest)
        } catch let error as NetworkingError {
            guard shouldFallbackToPut(from: error) else {
                throw error.toRepositoryError()
            }

            do {
                let putRequest = NovelReviewMapper.putNovelReviewRequest(from: draft)
                try await novelReviewService.putReview(
                    novelId: draft.novelID.value,
                    putRequest
                )
            } catch let putError as NetworkingError {
                throw putError.toRepositoryError()
            } catch {
                throw .unknown
            }
        } catch {
            throw .unknown
        }
    }
    
    public func deleteNovelReview(novelID: NovelID) async throws(RepositoryError) {
        <#code#>
    }
}
