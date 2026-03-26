//
//  MockNovelReviewService.swift
//  NovelReviewData
//
//  Created by YunhakLee on 3/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


@testable import NovelReviewData

final class MockNovelReviewService: NovelReviewService {
    var getReviewResult: Result<NovelReviewResponse, Error>!
    var postReviewResult: Result<Void, Error> = .success(())
    var putReviewResult: Result<Void, Error> = .success(())
    var deleteReviewResult: Result<Void, Error> = .success(())

    private(set) var requestedNovelID: Int?
    private(set) var postedRequest: PostNovelReviewRequest?
    private(set) var putNovelID: Int?
    private(set) var putRequest: PutNovelReviewRequest?
    private(set) var deletedNovelID: Int?

    func getReview(novelId: Int) async throws -> NovelReviewResponse {
        requestedNovelID = novelId
        return try getReviewResult.get()
    }

    func postReview(_ request: PostNovelReviewRequest) async throws {
        postedRequest = request
        _ = try postReviewResult.get()
    }

    func putReview(novelId: Int, _ request: PutNovelReviewRequest) async throws {
        putNovelID = novelId
        putRequest = request
        _ = try putReviewResult.get()
    }

    func deleteReview(novelId: Int) async throws {
        deletedNovelID = novelId
        _ = try deleteReviewResult.get()
    }
}
