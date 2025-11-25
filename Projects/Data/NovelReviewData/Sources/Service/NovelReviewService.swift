//
//  NovelReviewService.swift
//  NovelReviewData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation

protocol NovelReviewService {
    // MARK: - Review
    func postReview(_ request: PostNovelReviewRequest) async throws
    func getReview(novelId: Int) async throws -> NovelReviewResponse
    func putReview(novelId: Int, _ request: PutNovelReviewRequest) async throws
    func deleteReview(novelId: Int) async throws

    // MARK: - Interest
    func postInterest(novelId: Int) async throws
    func deleteInterest(novelId: Int) async throws
}
