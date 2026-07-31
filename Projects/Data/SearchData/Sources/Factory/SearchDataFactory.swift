//
//  SearchDataFactory.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import Foundation

import Networking
import SearchDomain
import BaseData

/// 모듈의 유일한 public 진입점.
public enum SearchDataFactory {
    public static func makeRepository(
        network: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> any RecentSearchRepository & SearchAutoCompletionRepository & SearchNovelRepository {
        let service = DefaultSearchService(network: network)
        return DefaultSearchRepository(
            service: service,
            logger: logger
        )
    }
}
