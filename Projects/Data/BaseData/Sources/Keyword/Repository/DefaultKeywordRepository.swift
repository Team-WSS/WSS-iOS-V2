//
//  DefaultKeywordRepository.swift
//  BaseData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct DefaultKeywordRepository: KeywordRepository {

    private let localStore: KeywordLocalStore
    private let syncManager: KeywordSyncManager
    private let logger: DataLogger?

    init(
        localStore: KeywordLocalStore,
        syncManager: KeywordSyncManager,
        logger: DataLogger?
    ) {
        self.localStore = localStore
        self.syncManager = syncManager
        self.logger = logger
    }

    @MainActor
    public func fetchKeywords() async throws(RepositoryError) -> [KeywordGroup] {
        let action = KeywordAction.searchByText

        do {
            let result = try localStore.fetchAll()
            logger?.logSuccess(action: action.text)
            return result
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }

    @MainActor
    public func searchKeywords(_ query: String) async throws(RepositoryError) -> [KeywordGroup] {
        let action = KeywordAction.searchByFilter(query: query)

        do {
            let result = try localStore.search(query)
            logger?.logSuccess(action: action.text)
            return result
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }

    public func syncKeywords() async {
        await syncManager.syncIfNeeded()
    }
}
