//
//  FeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct FeedUsecase: FeedUsecaseProtocol {
    
    private let repository: FeedRepositoryProtocol
    
    public init(repository: FeedRepositoryProtocol) {
        self.repository = repository
    }
    
    public func createFeed(draft: FeedDraft) async throws {
        switch draft.submissionValidationResult {
        case .valid:
            try await repository.submitFeed(draft)
        case .invalid(let reason):
            throw CreateFeedError.invalidDraft(reason: reason)
        }
    }
    
    public func editFeed(id: FeedID, draft: FeedDraft) async throws {
        switch draft.submissionValidationResult {
        case .valid:
            try await repository.editFeed(id: id, draft: draft)
        case .invalid(let reason):
            throw CreateFeedError.invalidDraft(reason: reason)
        }
    }
    
    public func deleteFeed(id: FeedID) async throws {
        try await repository.deleteFeed(id: id)
    }
    
    public func getFeedDetail(id: FeedID) async throws -> FeedDetail {
        try await repository.fetchFeedDetail(id: id)
    }
    
    // 타 유저의 피드 조회시 사용
    public func getUserFeeds(id: UserID, lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        try await repository.fetchUserFeeds(id: id, lastFeedID: lastFeedID)
    }
    
    // 전체 소소피드 조회시 사용
    public func getSosoFeeds(option: SosoFeedOption, lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        try await repository.fetchSosoFeeds(option: option, lastFeedID: lastFeedID)
    }
    
    // 내 피드 조회 시 사용
    public func getMyFeeds(option: MyFeedOption, lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        try await repository.fetchMyFeeds(option: option, lastFeedID: lastFeedID)
    }
}
