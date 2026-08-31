//
//  SettingDataFactory.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//

import Foundation

import BaseData
import Networking
import SettingDomain

public enum SettingDataFactory {
    /// 번들의 `CFBundleShortVersionString`을 읽는 앱 버전 소스 (#225).
    /// 네트워크를 타지 않아 client를 받지 않는 유일한 조립 진입점이다.
    public static func makeAppVersionProvider(bundle: Bundle = .main) -> AppVersionProviding {
        BundleAppVersionProvider(bundle: bundle)
    }

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
