//
//  NovelDataFactory.swift
//  NovelData
//
//  Created by Seoyeon Choi on 4/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Logger
import Networking
import NovelDomain

public enum NovelDataFactory {
    
    public static func makeNovelRepository(
        client: NetworkingRequestable,
        logger: NovelLogger? = DefaultNovelLogger(base: OSLogger.novel)
    ) -> NovelRepository {
        let service = DefaultNovelService(client: client)
        return DefaultNovelRepository(
            service: service,
            logger: logger
        )
    }
}
