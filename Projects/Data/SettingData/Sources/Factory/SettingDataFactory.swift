//
//  SettingDataFactory.swift
//  SettingData
//
//  Created by YunhakLee on 5/20/26.
//

import BaseData
import Networking
import SettingDomain

public enum SettingDataFactory {
    public static func makeAppUpdateRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> AppUpdateRepository {
        let service = DefaultSettingService(client: client)
        return DefaultAppUpdateRepository(
            settingService: service,
            logger: logger
        )
    }

    public static func makeTermsAgreementRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> TermsAgreementRepository {
        let service = DefaultSettingService(client: client)
        return DefaultTermsAgreementRepository(
            settingService: service,
            logger: logger
        )
    }
}
