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

public final class DefaultNovelRepository: NovelRepository {

    private let service: NovelService
    private let logger: NovelLogger?

    init(
        service: NovelService,
        logger: NovelLogger?
    ) {
        self.service = service
        self.logger = logger
    }

    public func fetchNovel(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        do {
            let basic = try await service.getNovelBasicInfo(novelID: id.value)
            let detail = try await service.getNovelDetailInfo(novelID: id.value)
            return try NovelMapper.novelInformation(id: id, from: basic, from: detail)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .fetchNovel, error: error)
            throw RepositoryError(from: error)
        } catch {
            logger?.logError(type: .unknown, action: .fetchNovel, error: error)
            throw .unknown
        }
    }

    public func addNovelInterest(id: NovelID) async throws(RepositoryError) {
        do {
            try await service.postNovelInterest(novelID: id.value)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .addInterest, error: error)
            throw RepositoryError(from: error)
        } catch {
            logger?.logError(type: .unknown, action: .addInterest, error: error)
            throw .unknown
        }
    }

    public func removeNovelInterest(id: NovelID) async throws(RepositoryError) {
        do {
            try await service.deleteNovelInterest(novelID: id.value)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .removeInterest, error: error)
            throw RepositoryError(from: error)
        } catch {
            logger?.logError(type: .unknown, action: .removeInterest, error: error)
            throw .unknown
        }
    }

    public func searchNovelByText(_ text: String) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        do {
            let query = NormalSearchQuery(
                query: text,
                page: 0,
                size: 20
            )
            let response = try await service.getNormalSearchNovels(query: query)
            let novels = response.novels.map { NovelMapper.searchNovel(from: $0) }
            let paginated = Paginated(items: novels, hasNext: response.isLoadable)
            return (paginated, response.resultCount)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .searchByText, error: error)
            throw RepositoryError(from: error)
        } catch {
            logger?.logError(type: .unknown, action: .searchByText, error: error)
            throw .unknown
        }
    }

    public func searchNovelByFilter(_ filter: SearchFilter) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        do {
            let query = NovelMapper.detailSearchQuery(from: filter)
            let response = try await service.getDetailSearchNovels(query: query)
            let novels = response.novels.map { NovelMapper.searchNovel(from: $0) }
            let paginated = Paginated(items: novels, hasNext: response.isLoadable)
            return (paginated, response.resultCount)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .searchByFilter, error: error)
            throw RepositoryError(from: error)
        } catch {
            logger?.logError(type: .unknown, action: .searchByFilter, error: error)
            throw .unknown
        }
    }

    public func fetchMyLibraryNovels(_ filter: MyLibraryFilter) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int) {
        do {
            //TODO: - UserDefaults에 저장된 유저아이디 값을 활용하여 넣어준다.
            let myID = UserDefaults.standard.integer(forKey: "myID")
            let query = NovelMapper.myLibraryQuery(from: filter)
            let response = try await service.getUserLibraryNovels(userID: myID, query: query)
            let libraryNovels = try NovelMapper.libraryNovels(from: response)
            return (libraryNovels.novels, libraryNovels.totalCount)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .fetchMyLibrary, error: error)
            throw RepositoryError(from: error)
        } catch {
            logger?.logError(type: .unknown, action: .fetchMyLibrary, error: error)
            throw .unknown
        }
    }

    public func fetchUserLibraryNovels(id: UserID, _ filter: LibraryFilter) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int) {
        do {
            let query = NovelMapper.userLibraryQuery(from: filter)
            let response = try await service.getUserLibraryNovels(userID: id.value, query: query)
            let libraryNovels = try NovelMapper.libraryNovels(from: response)
            return (libraryNovels.novels, libraryNovels.totalCount)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .fetchUserLibrary, error: error)
            throw RepositoryError(from: error)
        } catch {
            logger?.logError(type: .unknown, action: .fetchUserLibrary, error: error)
            throw .unknown
        }
    }

    public func fetchRegisteredNovelStats() async throws(RepositoryError) -> RegisteredNovelStats {
        do {
            //TODO: - UserDefaults에 저장된 유저아이디 값을 활용하여 넣어준다.
            let myID = UserDefaults.standard.integer(forKey: "myID")
            let response = try await service.getUserRegisteredNovelStats(userID: myID)
            return NovelMapper.userRegisteredNovelStats(from: response)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .fetchRegisteredStats, error: error)
            throw RepositoryError(from: error)
        } catch {
            logger?.logError(type: .unknown, action: .fetchRegisteredStats, error: error)
            throw .unknown
        }
    }
}
