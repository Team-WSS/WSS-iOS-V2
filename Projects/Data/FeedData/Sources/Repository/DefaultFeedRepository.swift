//
//  DefaultFeedRepository.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import FeedDomain
import BaseDomain
import BaseData
import Networking

public struct DefaultFeedRepository: FeedRepository {
    private let service: FeedService
    private let logger: DataLogger?
    private let storage: AppStorage
    private let pageSize = 20

    init(
        service: FeedService,
        logger: DataLogger? = nil,
        storage: AppStorage = UserDefaultsStorage()
    ) {
        self.service = service
        self.logger = logger
        self.storage = storage
    }

    public func submitFeed(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError) {
        let action = FeedAction.submitFeed

        let request = SubmitFeedRequest(
            feedContent: draft.content,
            relevantCategories: draft.genre.map { FeedMapper.genreString(from: $0) },
            novelId: draft.connectedNovel?.id.value,
            isSpoiler: draft.isSpoiler,
            isPublic: !draft.isPrivate,
            imageDatas: imageDatas
        )
        do {
            _ = try await service.postFeed(request: request)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func editFeed(id: FeedID, draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError) {
        let action = FeedAction.editFeed
        let request = SubmitFeedRequest(
            feedContent: draft.content,
            relevantCategories: draft.genre.map { FeedMapper.genreString(from: $0) },
            novelId: draft.connectedNovel?.id.value,
            isSpoiler: draft.isSpoiler,
            isPublic: !draft.isPrivate,
            imageDatas: imageDatas
        )
        do {
            _ = try await service.patchFeed(feedID: id.value, request: request)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func deleteFeed(id: FeedID) async throws(RepositoryError) {
        let action = FeedAction.deleteFeed
        do {
            try await service.deleteFeed(feedID: id.value)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchFeedDetail(id: FeedID) async throws(RepositoryError) -> FeedDetail {
        let action = FeedAction.fetchFeedDetail
        do {
            let response = try await service.getFeedDetail(feedID: id.value)
            let result = try FeedMapper.feedDetail(id: id, from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchSosoFeeds(option: SosoFeedOption, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        let action = FeedAction.fetchSosoFeeds
        let query = GetSosoFeedsQuery(
            category: nil,
            lastFeedId: lastFeedID.value,
            size: pageSize,
            option: option.rawValue
        )
        do {
            let response = try await service.getSosoFeeds(query: query)
            let result = FeedMapper.totalFeeds(from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchUserFeeds(id: UserID, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        let action = FeedAction.fetchUserFeeds
        let query = GetUserFeedsQuery(
            lastFeedId: lastFeedID.value,
            size: pageSize,
            isVisible: nil,
            isUnVisible: nil,
            genreNames: nil,
            sortCriteria: nil
        )
        do {
            let response = try await service.getUserFeeds(userID: id.value, query: query)
            let result = try FeedMapper.userFeeds(userID: id, from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchMyFeeds(option: MyFeedOption, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        let action = FeedAction.fetchMyFeeds
        let userID = storage.get(.userID) ?? 0
        let genres = option.genres.map { FeedMapper.genreString(from: $0) }
        let visibilityType = FeedMapper.visibilityString(from: option.visibilityType)
        let sortType = option.sortType.rawValue
        do {
            let response = try await service.getMyFeeds(
                userID: userID,
                genres: genres,
                visibilityType: visibilityType,
                sortType: sortType,
                lastFeedID: lastFeedID.value
            )
            let result = try FeedMapper.userFeeds(userID: UserID(userID), from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchNovelFeeds(id: NovelID, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        let action = FeedAction.fetchNovelFeeds
        do {
            let response = try await service.getNovelFeeds(novelID: id.value, lastFeedID: lastFeedID.value, size: pageSize)
            let result = try FeedMapper.novelFeeds(from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func addLike(id: FeedID) async throws(RepositoryError) {
        let action = FeedAction.addLike
        do {
            try await service.postLike(feedID: id.value)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func deleteLike(id: FeedID) async throws(RepositoryError) {
        let action = FeedAction.deleteLike
        do {
            try await service.deleteLike(feedID: id.value)
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
