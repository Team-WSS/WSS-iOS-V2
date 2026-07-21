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

public struct DefaultSearchRepository: RecentSearchRepository, SearchAutoCompletionRepository {

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
            return SearchMapper.recentSearchWords(from: response)
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
            return SearchMapper.searchAutoCompletionWords(from: response)
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
