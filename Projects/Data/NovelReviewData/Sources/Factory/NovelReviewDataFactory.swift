//
//  NovelReviewDataFactory.swift
//  NovelReviewData
//
//  Created by YunhakLee on 3/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import BaseData
import Networking
import NovelReviewDomain

public enum NovelReviewDataFactory {
    public static func makeRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> NovelReviewRepository {
        let service = DefaultNovelReviewService(client: client)
        return DefaultNovelReviewRepository(
            novelReviewService: service,
            logger: logger
        )
    }
}
