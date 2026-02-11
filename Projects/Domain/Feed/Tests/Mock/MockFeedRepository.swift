//
//  MockFeedRepository.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import FeedDomain
import BaseDomain

final class MockFeedRepository: FeedRepository {
    
    var submittedDrafts: [FeedDraft] = []
    var editedFeeds: [(id: FeedID, draft: FeedDraft)] = []
    var deletedFeedIDs: [FeedID] = []
    
    var fetchedDetailIDs: FeedID?
    
    var fetchedSosoFeeds: [(option: SosoFeedOption, lastFeedID: FeedID)] = []
    var fetchedUserFeeds: [(id: UserID, lastFeedID: FeedID)] = []
    var fetchedMyFeeds: [(option: MyFeedOption, lastFeedID: FeedID)] = []
    
    var addedLikeIDs: [FeedID] = []
    var deletedLikeIDs: [FeedID] = []
    
    var submitResult: Result<Void, Error> = .success(())
    var editResult: Result<Void, Error> = .success(())
    var deleteResult: Result<Void, Error> = .success(())
    
    var fetchDetailResult: Result<FeedDetail, Error>!
    
    var fetchSosoFeedsResult: Result<Paginated<TotalFeed>, Error>!
    var fetchUserFeedsResult: Result<Paginated<TotalFeed>, Error>!
    var fetchMyFeedsResult: Result<Paginated<TotalFeed>, Error>!
    
    var addLikeResult: Result<Void, Error> = .success(())
    var deleteLikeResult: Result<Void, Error> = .success(())
    
    var reportedSpoilerFeedID: FeedID?
    var reportSpoilerResult: Result<Void, Error> = .success(())
    var reportedImproperFeedID: FeedID?
    var reportImproperResult: Result<Void, Error> = .success(())
    
    func submitFeed(_ draft: FeedDraft) async throws {
        submittedDrafts.append(draft)
        switch submitResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func editFeed(id: FeedID, draft: FeedDraft) async throws {
        editedFeeds.append((id, draft))
        switch editResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func deleteFeed(id: FeedID) async throws {
        deletedFeedIDs.append(id)
        switch deleteResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func fetchFeedDetail(id: FeedID) async throws -> FeedDetail {
        fetchedDetailIDs = id
        switch fetchDetailResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .none:
            fatalError("fetchDetailResult must be set before calling fetchFeedDetail")
        }
    }
    
    func fetchSosoFeeds(option: SosoFeedOption, lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        fetchedSosoFeeds.append((option, lastFeedID))
        switch fetchSosoFeedsResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .none:
            fatalError("fetchSosoFeedsResult must be set before calling fetchSosoFeeds")
        }
    }
    
    func fetchUserFeeds(id: UserID, lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        fetchedUserFeeds.append((id, lastFeedID))
        switch fetchUserFeedsResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .none:
            fatalError("fetchUserFeedsResult must be set before calling fetchUserFeeds")
        }
    }
    
    func fetchMyFeeds(option: MyFeedOption, lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        fetchedMyFeeds.append((option, lastFeedID))
        switch fetchMyFeedsResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .none:
            fatalError("fetchMyFeedsResult must be set before calling fetchMyFeeds")
        }
    }
    
    
    // MARK: - Like
    
    func addLike(id: FeedID) async throws {
        addedLikeIDs.append(id)
        switch addLikeResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func deleteLike(id: FeedID) async throws {
        deletedLikeIDs.append(id)
        switch deleteLikeResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Report
    
    func reportSpoilerFeed(id: FeedID) async throws {
        reportedSpoilerFeedID = id
        
        switch reportSpoilerResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    func reportImproperFeed(id: FeedID) async throws {
        reportedImproperFeedID = id
        
        switch reportImproperResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
