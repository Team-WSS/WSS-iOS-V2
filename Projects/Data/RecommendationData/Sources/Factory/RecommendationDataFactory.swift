//
//  RecommendationDataFactory.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 3/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import Networking
import RecommendationDomain
import BaseData

public enum RecommendationDataFactory {
    public static func makeRepository(
        network: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> RecommendationRepository {
        let service = DefaultRecommendationService(network: network)
        return DefaultRecommendationRepository(
            service: service,
            logger: logger
        )
    }
}
