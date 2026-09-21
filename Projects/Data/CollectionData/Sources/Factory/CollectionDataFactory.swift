//
//  CollectionDataFactory.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import Networking
import CollectionDomain
import BaseData

/// 모듈의 유일한 public 진입점.
public enum CollectionDataFactory {
    public static func makeRepository(
        network: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> any CollectionRepository {
        let service = DefaultCollectionService(network: network)
        return DefaultCollectionRepository(
            service: service,
            logger: logger
        )
    }
}
