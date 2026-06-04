//
//  AuthDataFactory.swift
//  AuthData
//
//  Created by YunhakLee on 4/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import AuthDomain
import BaseData
import Networking

public enum AuthDataFactory {
    public static func makeRepository(
        client: NetworkingRequestable,
        tokenStore: TokenStore,
        deviceIdentifierStore: DeviceIdentifierStore,
        logger: DataLogger? = nil
    ) -> AuthRepository {
        let service = DefaultAuthService(client: client)

        return DefaultAuthRepository(
            service: service,
            tokenStore: tokenStore,
            deviceIdentifierStore: deviceIdentifierStore,
            logger: logger
        )
    }

    /// refresher가 없는 버전의 client 객체를 주입하면 됨.
    public static func makeSessionRefresher(
        client: NetworkingRequestable,
        tokenStore: TokenStore,
        logger: DataLogger? = nil
    ) -> AuthSessionRefreshing {
        let service = DefaultAuthService(client: client)
        return AuthSessionRefresher(
            service: service,
            tokenStore: tokenStore,
            logger: logger
        )
    }
}
