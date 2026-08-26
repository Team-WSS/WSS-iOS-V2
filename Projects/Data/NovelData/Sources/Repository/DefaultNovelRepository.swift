//
//  DefaultNovelRepository.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NovelDomain
import BaseDomain
import Networking
import BaseData

struct DefaultNovelRepository: NovelRepository {
    
    private let service: NovelService
    private let appStorage: AppStorage
    private let logger: DataLogger?

    init(
        service: NovelService,
        appStorage: AppStorage,
        logger: DataLogger?
    ) {
        self.service = service
        self.appStorage = appStorage
        self.logger = logger
    }

    public func fetchNovel(id: NovelID, cachedKeywords: [Keyword]) async throws(RepositoryError) -> NovelInformation {
        let action = NovelAction.fetchNovel
        do {
            let basic = try await service.getNovelBasicInfo(novelID: id.value)
            let detail = try await service.getNovelDetailInfo(novelID: id.value)

            let result = try NovelMapper.novelInformation(id: id,
                                                          from: basic,
                                                          from: detail,
                                                          cachedKeywords: cachedKeywords)
            logger?.logSuccess(action: action.text)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
    
    public func addNovelInterest(id: NovelID) async throws(RepositoryError) {
        let action = NovelAction.addInterest
        
        do {
            try await service.postNovelInterest(novelID: id.value)
            logger?.logSuccess(action: action.text)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
    
    public func removeNovelInterest(id: NovelID) async throws(RepositoryError) {
        let action = NovelAction.removeInterest
        
        do {
            try await service.deleteNovelInterest(novelID: id.value)
            logger?.logSuccess(action: action.text)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
    
    public func fetchMyLibraryNovels(
        _ filter: MyLibraryFilter,
        cursor: String?,
        size: Int,
        cachedKeywords: [Keyword]
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        let action = NovelAction.fetchMyLibrary

        do {
            let myID = appStorage.get(.userID)
            let query = NovelMapper.myLibraryV2Query(from: filter, cursor: cursor, size: size)
            let response = try await service.getUserLibraryNovelsV2(userID: myID ?? 0,
                                                                    query: query)
            let result = try NovelMapper.libraryNovelsV2(
                from: response,
                cachedKeywords: cachedKeywords
            )
            logger?.logSuccess(action: action.text)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
    
    public func fetchMyLibraryKeywords() async throws(RepositoryError) -> [Keyword] {
        let action = NovelAction.fetchMyLibraryKeywords

        do {
            let myID = appStorage.get(.userID)
            let response = try await service.getUserLibraryKeywords(userID: myID ?? 0)
            let result = NovelMapper.libraryKeywords(from: response)
            logger?.logSuccess(action: action.text)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }

    /// 타유저 서재 — 내 서재와 **같은 V2 엔드포인트**를 대상 userID로 호출한다
    /// (`fetchMyLibraryNovels`는 저장된 내 userID를 넣을 뿐 경로·쿼리는 동일하다).
    public func fetchUserLibraryNovels(
        id: UserID,
        _ filter: LibraryFilter,
        cursor: String?,
        cachedKeywords: [Keyword]
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        let action = NovelAction.fetchUserLibrary

        do {
            let query = NovelMapper.userLibraryV2Query(from: filter, cursor: cursor)
            let response = try await service.getUserLibraryNovelsV2(userID: id.value, query: query)
            let result = try NovelMapper.libraryNovelsV2(
                from: response,
                cachedKeywords: cachedKeywords
            )
            logger?.logSuccess(action: action.text)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
    
    public func fetchRegisteredNovelStats() async throws(RepositoryError) -> RegisteredNovelStats {
        let action = NovelAction.fetchRegisteredStats
        
        do {
            let myID = appStorage.get(.userID)
            let response = try await service.getUserRegisteredNovelStats(userID: myID ?? 0)
            let result = NovelMapper.userRegisteredNovelStats(from: response)
            logger?.logSuccess(action: action.text)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }

    public func fetchUserRegisteredNovelStats(id: UserID) async throws(RepositoryError) -> RegisteredNovelStats {
        let action = NovelAction.fetchUserRegisteredStats

        do {
            let response = try await service.getUserRegisteredNovelStats(userID: id.value)
            let result = NovelMapper.userRegisteredNovelStats(from: response)
            logger?.logSuccess(action: action.text)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
}
