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
import BaseData

public enum NovelDataFactory {
    public static func makeNovelRepository(
        client: NetworkingRequestable,
        appStorage: AppStorage,
        logger: DataLogger? = nil
    ) -> NovelRepository {
        let service = DefaultNovelService(client: client)
        let userDefaultsStorage = UserDefaultsStorage()
        return DefaultNovelRepository(
            service: service,
            appStorage: userDefaultsStorage,
            logger: logger
        )
    }

    /// 내 서재 필터·정렬 로컬 영속화 Repository(#221). 네트워크가 없어 `client`가 필요 없다 —
    /// `appStorage`(UserDefaults)만 의존한다. `NovelRepository`와 별개 계약이라 서버 조회 목킹과 무관.
    public static func makeMyLibraryFilterRepository(
        appStorage: AppStorage,
        logger: DataLogger? = nil
    ) -> MyLibraryFilterRepository {
        DefaultMyLibraryFilterRepository(
            appStorage: appStorage,
            logger: logger
        )
    }
}
