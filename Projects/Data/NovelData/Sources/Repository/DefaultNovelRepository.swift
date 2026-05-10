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

public struct DefaultNovelRepository: NovelRepository {
    
    private let service: NovelService
    private let appStorage: AppStorage
    private let keywordRepository: KeywordRepository
    private let logger: DataLogger?
    
    init(
        service: NovelService,
        appStorage: AppStorage,
        keywordRepository: KeywordRepository,
        logger: DataLogger?
    ) {
        self.service = service
        self.appStorage = appStorage
        self.keywordRepository = keywordRepository
        self.logger = logger
    }
    
    public func fetchNovel(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        let action = NovelAction.fetchNovel
        do {
            let basic = try await service.getNovelBasicInfo(novelID: id.value)
            let detail = try await service.getNovelDetailInfo(novelID: id.value)
            let cachedKeywords = (try? await keywordRepository.fetchKeywords())?.flatMap(\.keywords) ?? []
            
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
    
    public func searchNovelByText(_ text: String) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        let action = NovelAction.searchByText(query: text)
        let query = NormalSearchQuery(
            query: text,
            page: 0,
            size: 20
        )
        
        do {
            let response = try await service.getNormalSearchNovels(query: query)
            let result = NovelMapper.searchNovels(from: response)
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
    
    public func searchNovelByFilter(_ filter: SearchFilter) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        let action = NovelAction.searchByFilter
        
        do {
            let query = NovelMapper.detailSearchQuery(from: filter)
            let response = try await service.getDetailSearchNovels(query: query)
            let result = NovelMapper.searchNovels(from: response)
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
    
    public func fetchMyLibraryNovels(_ filter: MyLibraryFilter) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int) {
        let action = NovelAction.fetchMyLibrary
        
        do {
            let myID = appStorage.get(.userID)
            let query = NovelMapper.myLibraryQuery(from: filter)
            let response = try await service.getUserLibraryNovels(userID: myID ?? 0,
                                                                  query: query)
            let libraryNovels = try NovelMapper.libraryNovels(from: response)
            logger?.logSuccess(action: action.text)
            return (libraryNovels.novels, libraryNovels.totalCount)
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
    
    public func fetchUserLibraryNovels(id: UserID,
                                       _ filter: LibraryFilter) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int) {
        let action = NovelAction.fetchUserLibrary
        
        do {
            let query = NovelMapper.userLibraryQuery(from: filter)
            let response = try await service.getUserLibraryNovels(userID: id.value, query: query)
            let libraryNovels = try NovelMapper.libraryNovels(from: response)
            logger?.logSuccess(action: action.text)
            return (libraryNovels.novels, libraryNovels.totalCount)
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
}
