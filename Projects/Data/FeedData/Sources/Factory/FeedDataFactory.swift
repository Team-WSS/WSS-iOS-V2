//
//  FeedDataFactory.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Networking
import BaseData
import FeedDomain

public enum FeedDataFactory {

    public static func makeFeedRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> FeedRepository {
        let service = DefaultFeedService(client: client)
        return DefaultFeedRepository(service: service, logger: logger)
    }
}
