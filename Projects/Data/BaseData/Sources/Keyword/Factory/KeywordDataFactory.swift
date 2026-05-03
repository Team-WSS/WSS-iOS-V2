//
//  KeywordDataFactory.swift
//  BaseData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Networking
import BaseDomain

public enum KeywordDataFactory {
    public static func makeRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> KeywordRepository {
        let service = DefaultKeywordService(client: client)

        guard let localStore = try? KeywordLocalStore() else {
            fatalError("KeywordLocalStore 초기화 실패 — SwiftData 스키마를 확인하세요")
        }

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
