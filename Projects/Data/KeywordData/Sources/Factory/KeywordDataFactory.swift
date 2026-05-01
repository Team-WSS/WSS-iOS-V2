//
//  KeywordDataFactory.swift
//  KeywordData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Networking
import KeywordDomain
import BaseData

public enum KeywordDataFactory {
    public static func makeRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> KeywordRepository {
        let service = DefaultKeywordService(client: client)
        let localStore = try! KeywordLocalStore()
        let syncManager = KeywordSyncManager(
            keywordService: service,
            localStore: localStore,
            logger: logger
        )
        return DefaultKeywordRepository(
            localStore: localStore,
            syncManager: syncManager,
            logger: logger
        )
    }
}
