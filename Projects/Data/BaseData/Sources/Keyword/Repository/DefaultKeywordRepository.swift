//
//  DefaultKeywordRepository.swift
//  BaseData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain
import Networking

public struct DefaultKeywordRepository: KeywordRepository {

    private let keywordService: KeywordService
    private let cache: KeywordCache
    private let logger: DataLogger?

    init(
        keywordService: KeywordService,
        cache: KeywordCache,
        logger: DataLogger?
    ) {
        self.keywordService = keywordService
        self.cache = cache
        self.logger = logger
    }

    public func fetchKeywords() async throws(RepositoryError) -> [KeywordGroup] {
        let action = KeywordAction.fetchAll

        do {
            let cached = try cache.load()
            let result = KeywordMapper.keywordGroups(from: cached)
            logger?.logSuccess(action: action.text)
            return result
        } catch {
            logger?.logCacheError(action: action.text, error: error)
            throw .unknown
        }
    }

    public func searchKeywords(_ query: String) async throws(RepositoryError) -> [KeywordGroup] {
        let action = KeywordAction.searchByFilter(query: query)

        let allGroups = try await fetchKeywords()

        if query.isEmpty { return allGroups }

        let filtered = allGroups.compactMap { group -> KeywordGroup? in
            let matched = group.keywords.filter {
                $0.name.localizedCaseInsensitiveContains(query)
            }
            guard !matched.isEmpty else { return nil }
            return KeywordGroup(name: group.name, image: group.image, keywords: matched)
        }
        logger?.logSuccess(action: action.text)
        return filtered
    }

    public func syncKeywords() async {
        let action = KeywordAction.sync

        do {
            let request = SearchKeywordRequest(query: "")
            let response = try await keywordService.searchKeyword(request)
            try cache.save(response)
            logger?.logSuccess(action: action.text)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
        } catch let error as CacheError {
            logger?.logCacheError(action: action.text, error: error)
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
        }
    }
}
