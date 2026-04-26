//
//  CommentDataFactory.swift
//  CommentData
//
//  Created by Seoyeon Choi on 4/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Networking
import CommentDomain
import BaseData

public enum CommentDataFactory {
    public static func makeRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> CommentRepository {
        let service = DefaultCommentService(client: client)
        return DefaultCommentRepository(
            service: service,
            logger: logger
        )
    }
}
