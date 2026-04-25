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
import ProfileDomain

public enum ProfileDataFactory {

    public static func makeProfileRepository(
        client: NetworkingRequestable,
        localStorage: ProfileLocalStorage,
        underlying: Logger? = nil
    ) -> ProfileRepository {
        let service = DefaultProfileService(client: client)
        let logger = DataLogger(moduleName: "ProfileData", underlying: underlying)
        return DefaultProfileRepository(
            service: service,
            localStorage: localStorage,
            logger: logger
        )
    }
}
