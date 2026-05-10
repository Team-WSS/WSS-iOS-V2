//
//  ProfileDataFactory.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Logger
import Networking
import BaseData
import BaseDomain
import ProfileDomain

public enum ProfileDataFactory {

    public static func makeProfileRepository(
        client: NetworkingRequestable,
        localStorage: AppStorage,
        logger: DataLogger? = nil
    ) -> ProfileRepository {
        let service = DefaultProfileService(client: client)
        let keywordRepository = KeywordDataFactory.makeRepository(client: client, logger: logger)
        return DefaultProfileRepository(
            service: service,
            localStorage: localStorage,
            keywordRepository: keywordRepository,
            logger: logger
        )
    }
}
