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
    private let imageCompressor: ImageCompressor
    private let pageSize = 20

    init(
        service: FeedService,
        logger: DataLogger? = nil,
        storage: AppStorage = UserDefaultsStorage(),
        imageCompressor: ImageCompressor = ImageCompressor()
    ) {
        self.service = service
        self.logger = logger
        self.storage = storage
        self.imageCompressor = imageCompressor
    }

    public func submitFeed(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError) {
        let action = FeedAction.submitFeed

        let compressedImageDatas = await imageCompressor.compress(imageDatas)
        let request = SubmitFeedRequest(
            feedContent: draft.content,
            novelId: draft.connectedNovel?.id.value,
            isSpoiler: draft.isSpoiler,
            isPublic: !draft.isPrivate,
            imageDatas: compressedImageDatas
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

        let compressedImageDatas = await imageCompressor.compress(imageDatas)
        let request = SubmitFeedRequest(
            feedContent: draft.content,
            novelId: draft.connectedNovel?.id.value,
            isSpoiler: draft.isSpoiler,
            isPublic: !draft.isPrivate,
            imageDatas: compressedImageDatas
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
            lastFeedId: lastFeedID.value,
            size: pageSize,
            feedsOption: option.rawValue
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

    public func fetchUserFeeds(id: UserID, nickname: String, profileImage: URL?, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
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
            // "내 피드"는 fetchMyFeeds로 별도 조회하므로 여기서는 항상 타 유저 피드다.
            let result = try FeedMapper.userFeeds(
                author: Author(userId: id, nickname: nickname, profileImage: profileImage),
                isMyFeed: false,
                from: response
            )
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            // 상대가 프로필을 비공개로 설정한 경우 — HTTP 상태 코드보다 서버 비즈니스 코드로 식별한다.
            if case .responseFailure(_, let body) = error, body?.code == "USER-015" {
                throw .privateProfile
            }
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
        // 연결 작품이 없는(장르 없는) 피드는 서버 장르 필터에서 그냥 빠지므로, 그런 피드도 포함하려면
        // genreNames에 "etc"를 명시적으로 함께 보내야 한다(서버 스펙 — 실제 NovelGenre 값이 아니라 서버 전용 sentinel).
        var genres = option.genres.map { FeedMapper.genreString(from: $0) }
        if option.includesUncategorized {
            genres.append("etc")
        }
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
            let result = try FeedMapper.userFeeds(
                author: Author(userId: UserID(userID), nickname: "", profileImage: nil),
                isMyFeed: true,
                from: response
            )
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
