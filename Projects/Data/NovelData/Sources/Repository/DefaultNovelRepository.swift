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
    private let logger: DataLogger?

    init(
        service: NovelService,
        logger: DataLogger?
    ) {
        self.service = service
        self.logger = logger
    }

    public func fetchNovel(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        let action = NovelAction.fetchNovel
        do {
            let basic = try await service.getNovelBasicInfo(novelID: id.value)
            let detail = try await service.getNovelDetailInfo(novelID: id.value)
            return try NovelMapper.novelInformation(id: id, from: basic, from: detail)
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
        let action = NovelAction.searchByText
        let query = NormalSearchQuery(
            query: text,
            page: 0,
            size: 20
        )
        
        do {
            
            let response = try await service.getNormalSearchNovels(query: query)
            let novels = response.novels.map { NovelMapper.searchNovel(from: $0) }
            let paginated = Paginated(items: novels, hasNext: response.isLoadable)
            return (paginated, response.resultCount)
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
            let novels = response.novels.map { NovelMapper.searchNovel(from: $0) }
            let paginated = Paginated(items: novels, hasNext: response.isLoadable)
            return (paginated, response.resultCount)
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
            //TODO: - UserDefaults에 저장된 유저아이디 값을 활용하여 넣어준다.
            let myID = UserDefaults.standard.integer(forKey: "myID")
            let query = NovelMapper.myLibraryQuery(from: filter)
            let response = try await service.getUserLibraryNovels(userID: myID, query: query)
            let libraryNovels = try NovelMapper.libraryNovels(from: response)
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
            //TODO: - UserDefaults에 저장된 유저아이디 값을 활용하여 넣어준다.
            let myID = UserDefaults.standard.integer(forKey: "myID")
            let response = try await service.getUserRegisteredNovelStats(userID: myID)
            return NovelMapper.userRegisteredNovelStats(from: response)
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
