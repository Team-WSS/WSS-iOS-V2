//
//  NotificationDataFactory.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Networking
import NotificationDomain

public enum NotificationDataFactory {
    
    public static func makeNotificationRepository(
        client: NetworkingRequestable,
        logger: NotificationLogger? = nil
    ) -> NotificationRepository {
        let service = DefaultNotificationService(client: client)
        return DefaultNotificationRepository(
            notificationService: service,
            logger: logger
        )
    }
    
    public static func makePushSettingRepository(
        client: NetworkingRequestable,
        logger: PushSettingLogger? = nil
    ) -> PushSettingRepository {
        let service = DefaultPushSettingService(client: client)
        return DefaultPushSettingRepository(
            pushSettingService: service,
            logger: logger
        )
    }
}
