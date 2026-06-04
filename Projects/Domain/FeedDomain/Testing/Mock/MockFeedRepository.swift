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

public final class MockFeedRepository: FeedRepository {

    public var submittedDrafts: [FeedDraft] = []
    public var submittedImageDatas: [[Data]] = []
    public var editedFeeds: [(id: FeedID, draft: FeedDraft)] = []
    public var editedImageDatas: [[Data]] = []
    public var deletedFeedIDs: [FeedID] = []

    public var fetchedDetailIDs: FeedID?

    public var fetchedSosoFeeds: [(option: SosoFeedOption, lastFeedID: FeedID)] = []
    public var fetchedUserFeeds: [(id: UserID, lastFeedID: FeedID)] = []
    public var fetchedMyFeeds: [(option: MyFeedOption, lastFeedID: FeedID)] = []
    public var fetchedNovelFeeds: [(novelID: NovelID, lastFeedID: FeedID)] = []

    public var addedLikeIDs: [FeedID] = []
    public var deletedLikeIDs: [FeedID] = []

    public var submitResult: Result<Void, RepositoryError> = .success(())
    public var editResult: Result<Void, RepositoryError> = .success(())
    public var deleteResult: Result<Void, RepositoryError> = .success(())

    public var fetchDetailResult: Result<FeedDetail, RepositoryError>!

    public var fetchSosoFeedsResult: Result<Paginated<TotalFeed>, RepositoryError>!
    public var fetchUserFeedsResult: Result<Paginated<TotalFeed>, RepositoryError>!
    public var fetchMyFeedsResult: Result<Paginated<TotalFeed>, RepositoryError>!
    public var fetchNovelFeedsResult: Result<Paginated<TotalFeed>, RepositoryError>!

    public var addLikeResult: Result<Void, RepositoryError> = .success(())
    public var deleteLikeResult: Result<Void, RepositoryError> = .success(())

    public init() {}

    public func submitFeed(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError) {
        submittedDrafts.append(draft)
        submittedImageDatas.append(imageDatas)
        switch submitResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    public func editFeed(id: FeedID, draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError) {
        editedFeeds.append((id, draft))
        editedImageDatas.append(imageDatas)
        switch editResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    public func deleteFeed(id: FeedID) async throws(RepositoryError) {
        deletedFeedIDs.append(id)
        switch deleteResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    public func fetchFeedDetail(id: FeedID) async throws(RepositoryError) -> FeedDetail {
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

    public func fetchSosoFeeds(option: SosoFeedOption, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
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

    public func fetchUserFeeds(id: UserID, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
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

    public func fetchMyFeeds(option: MyFeedOption, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
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

    public func fetchNovelFeeds(id: NovelID, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        fetchedNovelFeeds.append((id, lastFeedID))
        switch fetchNovelFeedsResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .none:
            fatalError("fetchNovelFeedsResult must be set before calling fetchNovelFeeds")
        }
    }

    // MARK: - Like

    public func addLike(id: FeedID) async throws(RepositoryError) {
        addedLikeIDs.append(id)
        switch addLikeResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    public func deleteLike(id: FeedID) async throws(RepositoryError) {
        deletedLikeIDs.append(id)
        switch deleteLikeResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
