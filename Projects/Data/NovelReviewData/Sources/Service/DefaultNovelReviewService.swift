//
//  DefaultNovelReviewService.swift
//  NovelReviewData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking

final class DefaultNovelReviewService: NovelReviewService {
    private let client: NetworkingRequestable

    init(client: NetworkingRequestable) {
        self.client = client
    }

    // MARK: - Review

    func postReview(_ request: PostNovelReviewRequest) async throws {
        let endpoint = NovelReviewEndpoint.postReview(request)
        _ = try await client.request(endpoint)
    }

    func getReview(novelId: Int) async throws -> NovelReviewResponse {
        let endpoint = NovelReviewEndpoint.getReview(novelId: novelId)
        return try await client.request(endpoint, decodeTo: NovelReviewResponse.self)
    }

    func putReview(novelId: Int, _ request: PutNovelReviewRequest) async throws {
        let endpoint = NovelReviewEndpoint.putReview(novelId: novelId, request)
        _ = try await client.request(endpoint)
    }

    func deleteReview(novelId: Int) async throws {
        let endpoint = NovelReviewEndpoint.deleteReview(novelId: novelId)
        _ = try await client.request(endpoint)
    }
}
