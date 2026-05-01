//
//  SocialDataFactory.swift
//  SocialData
//
//  Created by YunhakLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Networking
import SocialDomain
import BaseData
import Logger

public enum SocialDataFactory {

    public static func makeSocialRepository(
        client: NetworkingRequestable,
        underlying: Logger? = nil
    ) -> SocialRepository {
        let service = DefaultSocialService(client: client)
        let logger = DataLogger(moduleName: "SocialData", underlying: underlying)
        return DefaultSocialRepository(service: service, logger: logger)
    }
}
