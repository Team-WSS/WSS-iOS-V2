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
    
    func getReview(novelId: Int) async throws -> NovelReviewResponse
    func postReview(_ request: PostNovelReviewRequest) async throws
    func putReview(novelId: Int, _ request: PutNovelReviewRequest) async throws
    func deleteReview(novelId: Int) async throws
}
