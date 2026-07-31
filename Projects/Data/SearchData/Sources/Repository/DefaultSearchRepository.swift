//
//  DefaultSearchRepository.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import Foundation

import SearchDomain
import BaseDomain
import Networking
import BaseData

public struct DefaultSearchRepository: RecentSearchRepository, SearchAutoCompletionRepository, SearchNovelRepository {

    private let service: SearchService
    private let logger: DataLogger?

    init(
        service: SearchService,
        logger: DataLogger?
    ) {
        self.service = service
        self.logger = logger
    }

    public func fetchRecentSearchWords() async throws(RepositoryError) -> [RecentSearchWord] {
        let action = SearchAction.fetchRecentSearchWords

        do {
            let response = try await service.getRecentSearchWords()
            let result = SearchMapper.recentSearchWords(from: response)
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

    public func removeRecentSearchWord(_ word: RecentSearchWord) async throws(RepositoryError) {
        let action = SearchAction.removeRecentSearchWord(word.title)

        do {
            try await service.deleteRecentSearchWord(id: word.id.value)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func clearRecentSearchWords() async throws(RepositoryError) {
        let action = SearchAction.clearRecentSearchWords

        do {
            try await service.deleteAllRecentSearchWords()
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchAutoCompletionWords(searchText: String) async throws(RepositoryError) -> [SearchAutoCompletionWord] {
        let action = SearchAction.searchAutoCompletionWords

        do {
            let response = try await service.getAutoCompletionWords(searchText: searchText)
            let result = SearchMapper.searchAutoCompletionWords(from: response)
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

    public func searchNovelByText(_ text: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        let action = SearchAction.searchNovelByText(query: text)
        let query = NormalSearchQuery(query: text, page: page, size: 20)

        do {
            let response = try await service.getNormalSearchNovels(query: query)
            let result = SearchMapper.searchNovels(from: response)
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

    public func searchNovelByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        let action = SearchAction.searchNovelByFilter

        do {
            let query = SearchMapper.detailSearchQuery(from: filter, page: page)
            let response = try await service.getDetailSearchNovels(query: query)
            let result = SearchMapper.searchNovels(from: response)
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
}
