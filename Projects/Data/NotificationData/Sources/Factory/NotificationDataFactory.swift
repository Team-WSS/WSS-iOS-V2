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

    public static func makeNovelNotificationSettingRepository(
        client: NetworkingRequestable,
        logger: DataLogger? = nil
    ) -> NovelNotificationSettingRepository {
        let service = DefaultNovelNotificationSettingService(client: client)
        return DefaultNovelNotificationSettingRepository(
            novelNotificationSettingService: service,
            logger: logger
        )
    }
}
