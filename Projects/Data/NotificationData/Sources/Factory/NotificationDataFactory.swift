//
//  NotificationDataFactory.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import BaseData
import Networking
import NotificationDomain

public enum NotificationDataFactory {

    public static func makeNotificationRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> NotificationRepository {
        let service = DefaultNotificationService(client: client)
        return DefaultNotificationRepository(
            notificationService: service,
            logger: logger
        )
    }

    public static func makePushSettingRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> PushSettingRepository {
        let service = DefaultPushSettingService(client: client)
        return DefaultPushSettingRepository(
            pushSettingService: service,
            logger: logger
        )
    }

    /// 작품 알림 구독 목록·일괄 해제(#188) + 작품별 완결/휴재복귀 알림 설정 조회·변경(#189) 공용 Repository.
    public static func makeNovelNotificationRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> NovelNotificationRepository {
        let service = DefaultNovelNotificationService(client: client)
        return DefaultNovelNotificationRepository(
            novelNotificationService: service,
            logger: logger
        )
    }
}
