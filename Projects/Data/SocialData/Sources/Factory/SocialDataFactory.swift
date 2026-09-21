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

public enum SocialDataFactory {

    public static func makeSocialRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> SocialRepository {
        let service = DefaultSocialService(client: client)
        return DefaultSocialRepository(service: service, logger: logger)
    }
}
